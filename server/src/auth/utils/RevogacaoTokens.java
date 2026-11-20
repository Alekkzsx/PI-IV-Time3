// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Blacklist de tokens revogados em memoria (ConcurrentHashMap) com limpeza automatica.
 *
 * Camada RAPIDA de revogacao (logout imediato sem ida ao banco). Limitacao consciente:
 * por ser em memoria, nao sobrevive a restart nem e compartilhada entre processos - a
 * revogacao DURAVEL fica na sessao do Mongo (auth_sessions), conferida pelo JwtAuthValidator.
 */
public final class RevogacaoTokens {
    // Singleton eager: sem estado externo, criacao na carga da classe e segura.
    private static final RevogacaoTokens INSTANCIA = new RevogacaoTokens();
    // Limpeza preguicosa a cada 60s (sem thread de timer): entradas expiradas nao tem valor de seguranca.
    private static final long INTERVALO_LIMPEZA_MS = 60_000;

    // jti -> instante de expiracao do token (epoch ms); depois do exp a blacklist nao precisa mais dele.
    private final ConcurrentHashMap<String, Long> tokensRevogados = new ConcurrentHashMap<String, Long>();
    private volatile long ultimaLimpeza = System.currentTimeMillis();

    private RevogacaoTokens() {}

    /** @return instancia unica compartilhada por validador e handlers de logout. */
    public static RevogacaoTokens getInstance() {
        return INSTANCIA;
    }

    /** Marca o jti como revogado ate expiraEmMillis (exp do token); chamada no logout/rotacao. */
    public void revogar(String jti, long expiraEmMillis) {
        if (jti == null || jti.trim().isEmpty()) {
            return;
        }
        tokensRevogados.put(jti.trim(), expiraEmMillis);
        limparExpiradosSeNecessario();
    }

    /**
     * @return true se o jti esta revogado E ainda dentro da validade;
     *         entrada expirada e removida e devolve false (o proprio exp do JWT ja barra).
     */
    public boolean estaRevogado(String jti) {
        if (jti == null || jti.trim().isEmpty()) {
            return false;
        }
        limparExpiradosSeNecessario();
        Long expira = tokensRevogados.get(jti.trim());
        if (expira == null) {
            return false;
        }
        if (System.currentTimeMillis() > expira) {
            tokensRevogados.remove(jti.trim());
            return false;
        }
        return true;
    }

    /** Varre e remove entradas expiradas no maximo 1x por minuto (chamado nas operacoes publicas). */
    private void limparExpiradosSeNecessario() {
        long agora = System.currentTimeMillis();
        if (agora - ultimaLimpeza < INTERVALO_LIMPEZA_MS) {
            return;
        }
        ultimaLimpeza = agora;
        Iterator<Map.Entry<String, Long>> iterador = tokensRevogados.entrySet().iterator();
        while (iterador.hasNext()) {
            Map.Entry<String, Long> entrada = iterador.next();
            if (agora > entrada.getValue()) {
                iterador.remove();
            }
        }
    }

    /** Zera a blacklist (uso exclusivo de testes). */
    public void limparTudo() {
        tokensRevogados.clear();
    }

    /** @return quantidade de jtis revogados ativos (diagnostico/testes). */
    public int tamanho() {
        limparExpiradosSeNecessario();
        return tokensRevogados.size();
    }
}
