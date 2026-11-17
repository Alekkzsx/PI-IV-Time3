// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

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
 * Limitador de tentativas de login implementado 100% em memoria com ConcurrentHashMap.
 * Protege contra ataques de forca bruta aplicando bloqueios temporarios.
 *
 * Regras (configuraveis via .env):
 * - MAX_FAILED_LOGIN_ATTEMPTS: maximo de tentativas falhas antes do bloqueio (padrao: 5)
 * - LOCKOUT_DURATION_SECONDS: duracao do bloqueio em segundos (padrao: 30)
 *
 * Janelas de bloqueio progressivo:
 * - Nivel 1 (5 falhas em 5 min): bloqueio de 30 segundos
 * - Nivel 2 (15 falhas em 15 min): bloqueio de 5 minutos
 * - Nivel 3 (30 falhas em 30 min): bloqueio de 30 minutos
 *
 * A identidade do atacante e composta por IP + usuario para maior granularidade.
 */
public final class LimitadorTentativas {

    private static final LimitadorTentativas INSTANCIA = new LimitadorTentativas();

    private final ConcurrentHashMap<String, RegistroTentativas> tentativas =
            new ConcurrentHashMap<String, RegistroTentativas>();

    private volatile long ultimaLimpeza = System.currentTimeMillis();
    private static final long INTERVALO_LIMPEZA_MS = 120_000; // 2 minutos

    private LimitadorTentativas() {}

    public static LimitadorTentativas getInstance() {
        return INSTANCIA;
    }

    /**
     * Verifica se a tentativa de login deve ser permitida.
     *
     * @param identidade Identidade do usuario (ex: email ou matricula).
     * @param ip         Endereco IP do cliente.
     * @return true se permitido, false se bloqueado.
     */
    public boolean permitirTentativa(String identidade, String ip) {
        limparExpiradosSeNecessario();

        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        // Verificar bloqueio persistido no MongoDB se inicializado
        if (estaBloqueadoNoBanco(chaveUsuario) || estaBloqueadoNoBanco(chaveIp)) {
            return false;
        }

        // Verificar bloqueio por usuario em memoria
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null && regUsuario.estaBloqueado()) {
            return false;
        }

        // Verificar bloqueio por IP em memoria
        RegistroTentativas regIp = tentativas.get(chaveIp);
        if (regIp != null && regIp.estaBloqueado()) {
            return false;
        }

        return true;
    }

    /**
     * Registra uma tentativa de login falha.
     *
     * @param identidade Identidade do usuario.
     * @param ip         Endereco IP do cliente.
     * @return Mensagem descritiva do estado (ex: "bloqueado por 30s", "3/5 tentativas").
     */
    public String registrarFalha(String identidade, String ip) {
        int maxTentativas = ConfigEnv.obterInteiro("MAX_FAILED_LOGIN_ATTEMPTS", 5);
        long lockoutMs = (long) ConfigEnv.obterInteiro("LOCKOUT_DURATION_SECONDS", 30) * 1000L;

        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        RegistroTentativas regUsuario = tentativas.computeIfAbsent(chaveUsuario,
                k -> new RegistroTentativas());
        RegistroTentativas regIp = tentativas.computeIfAbsent(chaveIp,
                k -> new RegistroTentativas());

        int falhasUsuario = regUsuario.registrarFalha(maxTentativas, lockoutMs);
        regIp.registrarFalha(maxTentativas * 3, lockoutMs * 5); // IP tolera mais falhas

        long bloqueioEfetivoMs = 0L;
        String mensagem;
        // Bloqueio progressivo
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
            long segundosRestantes = lockoutMs / 1000;
            mensagem = "Bloqueado por " + segundosRestantes + " segundos. Tente novamente depois.";
        } else {
            mensagem = "Credenciais invalidas. Tentativa " + falhasUsuario + " de " + maxTentativas + ".";
        }

        persistirFalhaNoBanco(chaveUsuario, falhasUsuario, bloqueioEfetivoMs);
        return mensagem;
    }

    /**
     * Registra um login bem-sucedido, resetando o contador de falhas.
     *
     * @param identidade Identidade do usuario.
     * @param ip         Endereco IP do cliente.
     */
    public void registrarSucesso(String identidade, String ip) {
        String chaveUsuario = "user:" + normalizar(identidade);
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null) {
            regUsuario.resetar();
        }
        limparBanco(chaveUsuario);
    }

    /**
     * Retorna quantos segundos de bloqueio restam para a identidade.
     */
    public long segundosRestantesBloqueio(String identidade) {
        String chave = "user:" + normalizar(identidade);
        long msBanco = segundosRestantesBanco(chave);
        RegistroTentativas reg = tentativas.get(chave);
        long msMem = reg != null ? reg.milissegundosRestantesBloqueio() : 0;
        long ms = Math.max(msBanco * 1000L, msMem);
        return ms > 0 ? (ms / 1000) + (ms % 1000 > 0 ? 1 : 0) : 0;
    }

    private MongoCollection<Document> colecaoLimites() {
        RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
        return repo != null ? repo.getLoginLimitsCollection() : null;
    }

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

    private void limparBanco(String chave) {
        MongoCollection<Document> col = colecaoLimites();
        if (col == null) return;
        try {
            col.deleteOne(Filters.eq("key", chave));
        } catch (Exception ignored) { }
    }

    private void limparExpiradosSeNecessario() {
        long agora = System.currentTimeMillis();
        if (agora - ultimaLimpeza < INTERVALO_LIMPEZA_MS) {
            return;
        }
        ultimaLimpeza = agora;

        Iterator<Map.Entry<String, RegistroTentativas>> iterador =
                tentativas.entrySet().iterator();
        while (iterador.hasNext()) {
            Map.Entry<String, RegistroTentativas> entrada = iterador.next();
            if (entrada.getValue().estaExpirado()) {
                iterador.remove();
            }
        }
    }

    private String normalizar(String valor) {
        if (valor == null) return "unknown";
        String limpo = valor.trim().toLowerCase();
        return limpo.isEmpty() ? "unknown" : limpo;
    }

    /**
     * Limpa todos os registros (para testes).
     */
    public void limparTudo() {
        tentativas.clear();
    }

    /**
     * Registro interno de tentativas por identidade.
     */
    private static final class RegistroTentativas {
        private final AtomicInteger contadorFalhas = new AtomicInteger(0);
        private volatile long bloqueadoAteMs = 0;
        private volatile long primeiraFalhaMs = 0;
        private volatile long ultimaFalhaMs = 0;
        private static final long JANELA_FALHAS_MS = 300_000; // 5 minutos

        synchronized int registrarFalha(int maxTentativas, long lockoutMs) {
            long agora = System.currentTimeMillis();

            // Se a primeira falha ja esta fora da janela, resetar
            if (primeiraFalhaMs > 0 && (agora - primeiraFalhaMs) > JANELA_FALHAS_MS) {
                contadorFalhas.set(0);
                primeiraFalhaMs = agora;
            }

            if (primeiraFalhaMs == 0) {
                primeiraFalhaMs = agora;
            }
            ultimaFalhaMs = agora;

            int total = contadorFalhas.incrementAndGet();
            return total;
        }

        synchronized void aplicarBloqueio(long duracaoMs) {
            bloqueadoAteMs = System.currentTimeMillis() + duracaoMs;
        }

        synchronized void resetar() {
            contadorFalhas.set(0);
            bloqueadoAteMs = 0;
            primeiraFalhaMs = 0;
            ultimaFalhaMs = 0;
        }

        boolean estaBloqueado() {
            if (bloqueadoAteMs <= 0) return false;
            if (System.currentTimeMillis() > bloqueadoAteMs) {
                bloqueadoAteMs = 0;
                contadorFalhas.set(0);
                return false;
            }
            return true;
        }

        long milissegundosRestantesBloqueio() {
            if (bloqueadoAteMs <= 0) return 0;
            long diff = bloqueadoAteMs - System.currentTimeMillis();
            return diff > 0 ? diff : 0;
        }

        boolean estaExpirado() {
            if (bloqueadoAteMs > 0 && System.currentTimeMillis() <= bloqueadoAteMs) {
                return false; // Ainda bloqueado, nao expirar
            }
            if (primeiraFalhaMs <= 0) return true;
            return (System.currentTimeMillis() - ultimaFalhaMs) > 600_000; // 10 min inativo
        }
    }
}
