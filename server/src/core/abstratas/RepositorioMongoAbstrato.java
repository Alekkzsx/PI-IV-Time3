// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
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
    protected static final Collation CASE_INSENSITIVE = Collation.builder()
            .locale("en")
            .collationStrength(CollationStrength.SECONDARY)
            .build();

    protected final ConexaoMongo conexao;
    private final MongoDatabase bancoFixo;
    private volatile boolean indicesInicializados = false;

    protected RepositorioMongoAbstrato(ConexaoMongo conexao) {
        this.conexao = conexao;
        this.bancoFixo = null;
    }

    protected RepositorioMongoAbstrato(MongoDatabase bancoFixo) {
        this.conexao = null;
        this.bancoFixo = bancoFixo;
    }

    /**
     * Subclasses declaram os indices de suas colecoes usando criarIndiceSeguro(...).
     */
    protected abstract void registrarIndices(MongoDatabase db);

    protected String tagLog() {
        return "MONGO";
    }

    protected MongoDatabase obterBancoSeAtivo() {
        if (bancoFixo != null) {
            return bancoFixo;
        }
        return conexao != null ? conexao.getDatabase() : null;
    }

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

    protected MongoCollection<Document> obterColecao(String nomeColecao) {
        return garantirBancoAtivo().getCollection(nomeColecao);
    }

    protected MongoCollection<Document> obterColecaoSeAtiva(String nomeColecao) {
        MongoDatabase db = obterBancoSeAtivo();
        return db != null ? db.getCollection(nomeColecao) : null;
    }

    protected RuntimeException tratarFalhaMongo(MongoException e, String contexto) {
        if (conexao != null) {
            return conexao.tratarFalhaMongo(e, contexto);
        }
        return DatabaseUnavailableException.fromThrowable(e);
    }

    /**
     * Dispara a criacao dos indices definidos pela subclasse em thread daemon sem bloquear o boot.
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
            if (e.getErrorCode() == 86) {
                try {
                    collection.dropIndex(indexName);
                    opts.name(indexName);
                    collection.createIndex(keys, opts);
                } catch (Exception retryEx) {
                    System.err.println("[" + tagLog() + "] Erro ao recriar indice " + indexName + ": " + retryEx.getMessage());
                }
            } else if (e.getErrorCode() != 85) {
                System.err.println("[" + tagLog() + "] Erro ao criar indice " + indexName
                        + " (code " + e.getErrorCode() + "): " + e.getMessage());
            }
        } catch (Exception e) {
            System.err.println("[" + tagLog() + "] Erro inesperado ao criar indice " + indexName + ": " + e.getMessage());
        }
    }
}
