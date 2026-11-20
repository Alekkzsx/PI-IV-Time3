// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import auth.modules.persistencia.RepositorioUsuarios;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import org.bson.Document;
import utils.ConfigEnv;

import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Limitador de tentativas de login com lockout progressivo (memoria + persistencia MongoDB).
 *
 * Duas dimensoes independentes: por identidade ("user:...") e por IP ("ip:...") -
 * barra tanto brute-force contra uma conta quanto spray a partir de uma origem.
 * Escalonamento por multiples de MAX_FAILED_LOGIN_ATTEMPTS (default 5):
 * >= 5 falhas -> lockout base (30s); >= 15 -> 10x (5min); >= 30 -> 60x (30min).
 * Memoria = caminho rapido; Mongo (auth_login_limits) = sobrevivencia a restart.
 * Falha de banco no rate limit e fail-OPEN de proposito: sem Mongo o login ja
 * falha por si so; o limitador nao deve virar ponto unico de indisponibilidade.
 */
public final class LimitadorTentativas {
    private static final LimitadorTentativas INSTANCIA = new LimitadorTentativas();
    // Varredura de registros ociosos a cada 2 minutos (sem thread dedicada).
    private static final long INTERVALO_LIMPEZA_MS = 120_000;

    // chave ("user:identidade" ou "ip:endereco") -> contador/janela/bloqueio daquela origem.
    private final ConcurrentHashMap<String, RegistroTentativas> tentativas =
            new ConcurrentHashMap<String, RegistroTentativas>();
    private volatile long ultimaLimpeza = System.currentTimeMillis();

    private LimitadorTentativas() {}

    /** @return instancia unica compartilhada pelos fluxos de login/2FA/recovery. */
    public static LimitadorTentativas getInstance() {
        return INSTANCIA;
    }

    /**
     * Portao de entrada do login: verifica bloqueio nas DUAS dimensoes (usuario e IP),
     * primeiro no banco (duravel) depois em memoria (rapido).
     *
     * @return false se qualquer dimensao estiver em lockout ativo
     */
    public boolean permitirTentativa(String identidade, String ip) {
        limparExpiradosSeNecessario();
        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        if (estaBloqueadoNoBanco(chaveUsuario) || estaBloqueadoNoBanco(chaveIp)) {
            return false;
        }
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null && regUsuario.estaBloqueado()) {
            return false;
        }
        RegistroTentativas regIp = tentativas.get(chaveIp);
        if (regIp != null && regIp.estaBloqueado()) {
            return false;
        }
        return true;
    }

    /**
     * Contabiliza uma falha nas duas dimensoes e aplica o lockout progressivo ao usuario.
     *
     * @return mensagem para o cliente (contagem atual ou tempo de bloqueio)
     */
    public String registrarFalha(String identidade, String ip) {
        int maxTentativas = ConfigEnv.obterInteiro("MAX_FAILED_LOGIN_ATTEMPTS", 5);
        long lockoutMs = (long) ConfigEnv.obterInteiro("LOCKOUT_DURATION_SECONDS", 30) * 1000L;

        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        RegistroTentativas regUsuario = tentativas.computeIfAbsent(chaveUsuario, k -> new RegistroTentativas());
        RegistroTentativas regIp = tentativas.computeIfAbsent(chaveIp, k -> new RegistroTentativas());

        int falhasUsuario = regUsuario.registrarFalha();
        regIp.registrarFalha();

        long bloqueioEfetivoMs = 0L;
        String mensagem;
        // Degraus: 6x o limite -> 60x lockout (30min); 3x -> 10x (5min); 1x -> base (30s).
        if (falhasUsuario >= maxTentativas * 6) {
            bloqueioEfetivoMs = lockoutMs * 60;
            regUsuario.aplicarBloqueio(bloqueioEfetivoMs);
            mensagem = "Bloqueado por 30 minutos devido a excesso de tentativas.";
        } else if (falhasUsuario >= maxTentativas * 3) {
            bloqueioEfetivoMs = lockoutMs * 10;
            regUsuario.aplicarBloqueio(bloqueioEfetivoMs);
            mensagem = "Bloqueado por 5 minutos devido a excesso de tentativas.";
        } else if (falhasUsuario >= maxTentativas) {
            bloqueioEfetivoMs = lockoutMs;
            regUsuario.aplicarBloqueio(bloqueioEfetivoMs);
            mensagem = "Bloqueado por " + (lockoutMs / 1000) + " segundos. Tente novamente depois.";
        } else {
            mensagem = "Credenciais invalidas. Tentativa " + falhasUsuario + " de " + maxTentativas + ".";
        }

        persistirFalhaNoBanco(chaveUsuario, falhasUsuario, bloqueioEfetivoMs);
        return mensagem;
    }

    /** Login bem-sucedido zera o contador do usuario (memoria + banco); o IP nao e zerado aqui. */
    public void registrarSucesso(String identidade, String ip) {
        String chaveUsuario = "user:" + normalizar(identidade);
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null) {
            regUsuario.resetar();
        }
        limparBanco(chaveUsuario);
    }

    /** Segundos restantes do MAIOR bloqueio entre memoria e banco, arredondados para cima (retry-after). */
    public long segundosRestantesBloqueio(String identidade) {
        String chave = "user:" + normalizar(identidade);
        long msBanco = segundosRestantesBanco(chave);
        RegistroTentativas reg = tentativas.get(chave);
        long msMem = reg != null ? reg.milissegundosRestantesBloqueio() : 0;
        long ms = Math.max(msBanco * 1000L, msMem);
        return ms > 0 ? (ms / 1000) + (ms % 1000 > 0 ? 1 : 0) : 0;
    }

    /** @return colecao auth_login_limits ou null se o repositorio nao foi inicializado (modo so-memoria). */
    private MongoCollection<Document> colecaoLimites() {
        RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
        return repo != null ? repo.getLoginLimitsCollection() : null;
    }

    /** Bloqueio duravel no banco; erro de rede devolve false (fail-open, ver Javadoc da classe). */
    private boolean estaBloqueadoNoBanco(String chave) {
        MongoCollection<Document> col = colecaoLimites();
        if (col == null) return false;
        try {
            Document doc = col.find(Filters.eq("key", chave)).first();
            if (doc == null) return false;
            Date lockedUntil = doc.getDate("lockedUntil");
            return lockedUntil != null && lockedUntil.getTime() > System.currentTimeMillis();
        } catch (Exception e) {
            return false;
        }
    }

    /** Segundos restantes do lockedUntil persistido (0 se ausente/expirado/erro). */
    private long segundosRestantesBanco(String chave) {
        MongoCollection<Document> col = colecaoLimites();
        if (col == null) return 0;
        try {
            Document doc = col.find(Filters.eq("key", chave)).first();
            if (doc == null) return 0;
            Date lockedUntil = doc.getDate("lockedUntil");
            if (lockedUntil == null) return 0;
            long diff = lockedUntil.getTime() - System.currentTimeMillis();
            return diff > 0 ? (diff / 1000L) + 1L : 0L;
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * Upsert da falha em auth_login_limits. expiresAt (TTL index) fica no minimo 10min a frente
     * para o registro nao sumir entre tentativas espacadas; lockedUntil so e gravado em lockout.
     */
    private void persistirFalhaNoBanco(String chave, int falhas, long bloqueioMs) {
        MongoCollection<Document> col = colecaoLimites();
        if (col == null) return;
        try {
            Date agora = new Date();
            Date expiresAt = new Date(System.currentTimeMillis() + Math.max(bloqueioMs, 600_000L));
            if (bloqueioMs > 0) {
                col.updateOne(
                        Filters.eq("key", chave),
                        Updates.combine(
                                Updates.set("key", chave),
                                Updates.set("failedAttempts", falhas),
                                Updates.set("lockedUntil", new Date(System.currentTimeMillis() + bloqueioMs)),
                                Updates.set("expiresAt", expiresAt),
                                Updates.set("updatedAt", agora)
                        ),
                        new UpdateOptions().upsert(true)
                );
            } else {
                col.updateOne(
                        Filters.eq("key", chave),
                        Updates.combine(
                                Updates.set("key", chave),
                                Updates.set("failedAttempts", falhas),
                                Updates.set("expiresAt", expiresAt),
                                Updates.set("updatedAt", agora)
                        ),
                        new UpdateOptions().upsert(true)
                );
            }
        } catch (Exception ignored) { }
    }

    /** Remove o registro persistido no login bem-sucedido. */
    private void limparBanco(String chave) {
        MongoCollection<Document> col = colecaoLimites();
        if (col == null) return;
        try {
            col.deleteOne(Filters.eq("key", chave));
        } catch (Exception ignored) { }
    }

    /** Limpeza preguicosa (max 1x/2min) de registros sem bloqueio ativo e ociosos. */
    private void limparExpiradosSeNecessario() {
        long agora = System.currentTimeMillis();
        if (agora - ultimaLimpeza < INTERVALO_LIMPEZA_MS) {
            return;
        }
        ultimaLimpeza = agora;
        Iterator<Map.Entry<String, RegistroTentativas>> iterador = tentativas.entrySet().iterator();
        while (iterador.hasNext()) {
            if (iterador.next().getValue().estaExpirado()) {
                iterador.remove();
            }
        }
    }

    /** Normaliza a chave: trim + lowercase (identidade case-insensitive); vazio vira "unknown". */
    private String normalizar(String valor) {
        if (valor == null) return "unknown";
        String limpo = valor.trim().toLowerCase();
        return limpo.isEmpty() ? "unknown" : limpo;
    }

    /** Zera o estado em memoria (uso exclusivo de testes). */
    public void limparTudo() {
        tentativas.clear();
    }

    /**
     * Estado de uma origem (usuario ou IP): contador de falhas dentro de uma janela
     * deslizante de 5 minutos + instante de fim de bloqueio. Metodos de mutacao sao
     * synchronized; leituras usam volatile/atomic para nao travar o caminho quente.
     */
    private static final class RegistroTentativas {
        private final AtomicInteger contadorFalhas = new AtomicInteger(0);
        private volatile long bloqueadoAteMs = 0;
        private volatile long primeiraFalhaMs = 0;
        private volatile long ultimaFalhaMs = 0;
        // Janela de contagem: falhas mais antigas que 5min nao acumulam para o lockout.
        private static final long JANELA_FALHAS_MS = 300_000;

        /** Incrementa e devolve o total de falhas; reinicia a contagem se a janela de 5min estourou. */
        synchronized int registrarFalha() {
            long agora = System.currentTimeMillis();
            if (primeiraFalhaMs > 0 && (agora - primeiraFalhaMs) > JANELA_FALHAS_MS) {
                contadorFalhas.set(0);
                primeiraFalhaMs = agora;
            }
            if (primeiraFalhaMs == 0) {
                primeiraFalhaMs = agora;
            }
            ultimaFalhaMs = agora;
            return contadorFalhas.incrementAndGet();
        }

        /** Define o fim do bloqueio a partir de agora (sobrescreve bloqueio anterior). */
        synchronized void aplicarBloqueio(long duracaoMs) {
            bloqueadoAteMs = System.currentTimeMillis() + duracaoMs;
        }

        /** Zera contador/bloqueio/janela (login ok). */
        synchronized void resetar() {
            contadorFalhas.set(0);
            bloqueadoAteMs = 0;
            primeiraFalhaMs = 0;
            ultimaFalhaMs = 0;
        }

        /** Bloqueio ativo? Expirado limpa o estado na hora (auto-recuperacao sem timer). */
        boolean estaBloqueado() {
            if (bloqueadoAteMs <= 0) return false;
            if (System.currentTimeMillis() > bloqueadoAteMs) {
                bloqueadoAteMs = 0;
                contadorFalhas.set(0);
                return false;
            }
            return true;
        }

        /** @return ms restantes do bloqueio (0 se nao bloqueado). */
        long milissegundosRestantesBloqueio() {
            if (bloqueadoAteMs <= 0) return 0;
            long diff = bloqueadoAteMs - System.currentTimeMillis();
            return diff > 0 ? diff : 0;
        }

        /** Elegivel para limpeza: sem bloqueio ativo e sem falhas nos ultimos 10 minutos. */
        boolean estaExpirado() {
            if (bloqueadoAteMs > 0 && System.currentTimeMillis() <= bloqueadoAteMs) {
                return false;
            }
            if (primeiraFalhaMs <= 0) return true;
            return (System.currentTimeMillis() - ultimaFalhaMs) > 600_000;
        }
    }
}
