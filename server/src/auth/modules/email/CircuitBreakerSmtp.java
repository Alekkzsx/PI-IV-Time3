// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalEnvioEmailAbstrato;

/**
 * Circuit Breaker thread-safe para o canal SMTP (CLOSED -> OPEN -> HALF_OPEN).
 * Abre o circuito apos 3 falhas consecutivas e aplica cooldown de 60 segundos.
 */
public final class CircuitBreakerSmtp {
    // 3 falhas consecutivas abrem o circuito; 60s de cooldown antes da sonda HALF_OPEN.
    private static final int MAX_FALHAS_CIRCUITO = 3;
    private static final long COOLDOWN_CIRCUITO_MS = 60_000L;

    // Lock unico protege a maquina de estados (transicoes sao compostas: ler estado + mudar).
    private final Object lock = new Object();
    private String estado = "CLOSED";
    private int falhasConsecutivas = 0;
    private long proximaTentativaMs = 0L;

    /** @return estado atual (CLOSED normal, OPEN bloqueando, HALF_OPEN sondando). */
    public String getEstado() {
        synchronized (lock) {
            return estado;
        }
    }

    /**
     * Portao de tentativa: CLOSED/HALF_OPEN deixam passar; OPEN so apos o cooldown,
     * momento em que transiciona para HALF_OPEN (uma sonda real decide o proximo estado).
     */
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

    /** Qualquer sucesso fecha o circuito e zera o contador (recuperacao total). */
    public void registrarSucesso() {
        synchronized (lock) {
            falhasConsecutivas = 0;
            estado = "CLOSED";
            proximaTentativaMs = 0L;
        }
    }

    /** Conta a falha; ao atingir o limiar abre o circuito e agenda o fim do cooldown. */
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

    /** @return true se o circuito esta OPEN (pula o SMTP imediatamente). */
    public boolean estaAberto() {
        return "OPEN".equals(getEstado());
    }

    /** Volta ao estado inicial (uso exclusivo de testes). */
    public void resetar() {
        synchronized (lock) {
            estado = "CLOSED";
            falhasConsecutivas = 0;
            proximaTentativaMs = 0L;
        }
    }
}
