// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core.abstratas;

import com.mongodb.MongoCommandException;
import com.mongodb.MongoException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Collation;
import com.mongodb.client.model.CollationStrength;
import com.mongodb.client.model.IndexOptions;
import core.ConexaoMongo;
import core.DatabaseUnavailableException;
import org.bson.Document;

/**
 * Classe abstrata base para todos os repositorios persistidos em MongoDB (Padrao Template Method).
 *
 * Centraliza:
 * - Acesso seguro ao banco de dados (via ConexaoMongo compartilhada ou MongoDatabase injetado);
 * - Inicializacao assincrona e idempotente de indices com resolucao automatica de conflitos (codigos 85/86);
 * - Traducao padronizada de MongoException para DatabaseUnavailableException (HTTP 503).
 */
public abstract class RepositorioMongoAbstrato {
    // Collation secundaria = compara sem diferenciar maiusculas/acentos: e-mails e usernames
    // unicos independente de caixa ("Alekk@x.com" == "alekk@x.com").
    protected static final Collation CASE_INSENSITIVE = Collation.builder()
            .locale("en")
            .collationStrength(CollationStrength.SECONDARY)
            .build();

    protected final ConexaoMongo conexao;
    private final MongoDatabase bancoFixo;
    // volatile + synchronized em garantirIndices(): dupla checagem para inicializar indices uma unica vez.
    private volatile boolean indicesInicializados = false;

    /** Modo producao: usa a ConexaoMongo compartilhada (com failover e healthcheck). */
    protected RepositorioMongoAbstrato(ConexaoMongo conexao) {
        this.conexao = conexao;
        this.bancoFixo = null;
    }

    /** Modo teste/integracao: banco fixo injetado, sem singleton nem failover. */
    protected RepositorioMongoAbstrato(MongoDatabase bancoFixo) {
        this.conexao = null;
        this.bancoFixo = bancoFixo;
    }

    /**
     * Subclasses declaram os indices de suas colecoes usando criarIndiceSeguro(...).
     */
    protected abstract void registrarIndices(MongoDatabase db);

    /** Tag de log; subclasses especializam (ex.: MONGO-USERS) para filtrar o console. */
    protected String tagLog() {
        return "MONGO";
    }

    /** @return banco atual ou null quando offline (para caminhos tolerantes a indisponibilidade). */
    protected MongoDatabase obterBancoSeAtivo() {
        if (bancoFixo != null) {
            return bancoFixo;
        }
        return conexao != null ? conexao.getDatabase() : null;
    }

    /** Versao fail-fast: lanca DatabaseUnavailableException (503) se nao houver banco utilizavel. */
    protected MongoDatabase garantirBancoAtivo() {
        if (bancoFixo != null) {
            return bancoFixo;
        }
        if (conexao != null) {
            return conexao.garantirBancoAtivo();
        }
        throw new DatabaseUnavailableException(
                503,
                "database_network_blocked",
                "Banco de dados inacessivel a partir desta rede.",
                null
        );
    }

    /** Obtem colecao exigindo banco ativo (503 se offline). */
    protected MongoCollection<Document> obterColecao(String nomeColecao) {
        return garantirBancoAtivo().getCollection(nomeColecao);
    }

    /** Obtem colecao ou null se o banco estiver offline (sem lancar). */
    protected MongoCollection<Document> obterColecaoSeAtiva(String nomeColecao) {
        MongoDatabase db = obterBancoSeAtivo();
        return db != null ? db.getCollection(nomeColecao) : null;
    }

    /** Delega a traducao/failover para a ConexaoMongo; com banco fixo, traduz direto para 503. */
    protected RuntimeException tratarFalhaMongo(MongoException e, String contexto) {
        if (conexao != null) {
            return conexao.tratarFalhaMongo(e, contexto);
        }
        return DatabaseUnavailableException.fromThrowable(e);
    }

    /**
     * Dispara a criacao dos indices definidos pela subclasse em thread daemon sem bloquear o boot.
     * Daemon de proposito: criacao de indice pendente nao pode impedir o encerramento da JVM.
     *
     * @param nomeThread nome da thread para diagnostico (ex.: "mongo-users-indexes")
     */
    public final void inicializarIndicesAsync(final String nomeThread) {
        if (indicesInicializados) {
            return;
        }
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                garantirIndices();
            }
        }, nomeThread);
        t.setDaemon(true);
        t.start();
    }

    /**
     * Garante a criacao dos indices exatamente uma vez (dupla checagem com synchronized).
     * Falha nao marca como inicializado: a proxima chamada tenta de novo. Erros sao apenas
     * logados - indice ausente degrada performance, nao pode derrubar o servidor.
     */
    public final void garantirIndices() {
        if (indicesInicializados) {
            return;
        }
        MongoDatabase db = obterBancoSeAtivo();
        if (db == null) {
            return;
        }
        synchronized (this) {
            if (indicesInicializados) {
                return;
            }
            try {
                registrarIndices(db);
                indicesInicializados = true;
            } catch (Exception e) {
                System.err.println("[" + tagLog() + "] Aviso ao inicializar indices: " + e.getMessage());
            }
        }
    }

    /**
     * Cria um indice de forma segura, resolvendo conflitos de definicao (codigo 86) e indices compativeis (codigo 85).
     * Codigos do servidor Mongo: 85 = IndexOptionsConflict (mesmo nome, opcoes diferentes),
     * 86 = IndexKeySpecsConflict (mesmo nome, chaves diferentes) -> dropa e recria com a definicao nova.
     * Idempotente: rodar de novo com a mesma definicao nao gera erro.
     */
    protected final void criarIndiceSeguro(
            MongoCollection<Document> collection,
            String indexName,
            Document keys,
            IndexOptions options) {
        if (collection == null) {
            return;
        }
        IndexOptions opts = options != null ? options : new IndexOptions();
        try {
            opts.name(indexName);
            collection.createIndex(keys, opts);
        } catch (MongoCommandException e) {
            // 86: definicao de chaves mudou entre versoes do schema -> recriar do zero.
            if (e.getErrorCode() == 86) {
                try {
                    collection.dropIndex(indexName);
                    opts.name(indexName);
                    collection.createIndex(keys, opts);
                } catch (Exception retryEx) {
                    System.err.println("[" + tagLog() + "] Erro ao recriar indice " + indexName + ": " + retryEx.getMessage());
                }
            // 85: conflito apenas de opcoes com indice equivalente -> tolerado silenciosamente.
            } else if (e.getErrorCode() != 85) {
                System.err.println("[" + tagLog() + "] Erro ao criar indice " + indexName
                        + " (code " + e.getErrorCode() + "): " + e.getMessage());
            }
        } catch (Exception e) {
            System.err.println("[" + tagLog() + "] Erro inesperado ao criar indice " + indexName + ": " + e.getMessage());
        }
    }
}
