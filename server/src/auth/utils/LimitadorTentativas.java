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
 */
public final class LimitadorTentativas {
    private static final LimitadorTentativas INSTANCIA = new LimitadorTentativas();
    private static final long INTERVALO_LIMPEZA_MS = 120_000;

    private final ConcurrentHashMap<String, RegistroTentativas> tentativas =
            new ConcurrentHashMap<String, RegistroTentativas>();
    private volatile long ultimaLimpeza = System.currentTimeMillis();

    private LimitadorTentativas() {}

    public static LimitadorTentativas getInstance() {
        return INSTANCIA;
    }

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

    public void registrarSucesso(String identidade, String ip) {
        String chaveUsuario = "user:" + normalizar(identidade);
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null) {
            regUsuario.resetar();
        }
        limparBanco(chaveUsuario);
    }

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
        Iterator<Map.Entry<String, RegistroTentativas>> iterador = tentativas.entrySet().iterator();
        while (iterador.hasNext()) {
            if (iterador.next().getValue().estaExpirado()) {
                iterador.remove();
            }
        }
    }

    private String normalizar(String valor) {
        if (valor == null) return "unknown";
        String limpo = valor.trim().toLowerCase();
        return limpo.isEmpty() ? "unknown" : limpo;
    }

    public void limparTudo() {
        tentativas.clear();
    }

    private static final class RegistroTentativas {
        private final AtomicInteger contadorFalhas = new AtomicInteger(0);
        private volatile long bloqueadoAteMs = 0;
        private volatile long primeiraFalhaMs = 0;
        private volatile long ultimaFalhaMs = 0;
        private static final long JANELA_FALHAS_MS = 300_000;

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
                return false;
            }
            if (primeiraFalhaMs <= 0) return true;
            return (System.currentTimeMillis() - ultimaFalhaMs) > 600_000;
        }
    }
}
