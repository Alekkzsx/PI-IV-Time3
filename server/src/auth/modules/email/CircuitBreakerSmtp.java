// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalEnvioEmailAbstrato;

/**
 * Circuit Breaker thread-safe para o canal SMTP (CLOSED -> OPEN -> HALF_OPEN).
 * Abre o circuito apos 3 falhas consecutivas e aplica cooldown de 60 segundos.
 */
public final class CircuitBreakerSmtp {
    private static final int MAX_FALHAS_CIRCUITO = 3;
    private static final long COOLDOWN_CIRCUITO_MS = 60_000L;

    private final Object lock = new Object();
    private String estado = "CLOSED";
    private int falhasConsecutivas = 0;
    private long proximaTentativaMs = 0L;

    public String getEstado() {
        synchronized (lock) {
            return estado;
        }
    }

    public boolean permitirTentativa() {
        long agora = System.currentTimeMillis();
        synchronized (lock) {
            if ("CLOSED".equals(estado)) {
                return true;
            }
            if ("OPEN".equals(estado)) {
                if (agora >= proximaTentativaMs) {
                    estado = "HALF_OPEN";
                    return true;
                }
                return false;
            }
            return true;
        }
    }

    public void registrarSucesso() {
        synchronized (lock) {
            falhasConsecutivas = 0;
            estado = "CLOSED";
            proximaTentativaMs = 0L;
        }
    }

    public void registrarFalha(String motivo) {
        synchronized (lock) {
            falhasConsecutivas++;
            if (falhasConsecutivas >= MAX_FALHAS_CIRCUITO) {
                estado = "OPEN";
                proximaTentativaMs = System.currentTimeMillis() + COOLDOWN_CIRCUITO_MS;
                CanalEnvioEmailAbstrato.log("WARN", "[CIRCUITO SMTP ABERTO] Apos " + falhasConsecutivas
                        + " falhas consecutivas (" + motivo + "). Cooldown de 60s.");
            }
        }
    }

    public boolean estaAberto() {
        return "OPEN".equals(getEstado());
    }

    public void resetar() {
        synchronized (lock) {
            estado = "CLOSED";
            falhasConsecutivas = 0;
            proximaTentativaMs = 0L;
        }
    }
}
