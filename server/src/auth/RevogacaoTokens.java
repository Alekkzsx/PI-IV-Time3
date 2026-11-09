// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Blacklist de tokens revogados implementada 100% em memoria com ConcurrentHashMap.
 * Armazena o JTI (JWT ID) e a data de expiracao para limpeza automatica.
 *
 * Quando um usuario faz logout, seu JTI e adicionado aqui.
 * O JwtAuthValidator verifica esta blacklist antes de aceitar um token.
 *
 * Para ambientes multi-instancia, considerar migrar para Redis ou MongoDB.
 */
public final class RevogacaoTokens {

    private static final RevogacaoTokens INSTANCIA = new RevogacaoTokens();

    // jti -> timestamp de expiracao em millis (quando remover da memoria)
    private final ConcurrentHashMap<String, Long> tokensRevogados = new ConcurrentHashMap<String, Long>();

    // Limpeza automatica: remove entradas expiradas
    private volatile long ultimaLimpeza = System.currentTimeMillis();
    private static final long INTERVALO_LIMPEZA_MS = 60_000; // 1 minuto

    private RevogacaoTokens() {}

    public static RevogacaoTokens getInstance() {
        return INSTANCIA;
    }

    /**
     * Revoga um token adicionando seu JTI a blacklist.
     *
     * @param jti            Identificador unico do token (claim "jti").
     * @param expiraEmMillis Timestamp absoluto (epoch millis) quando o token expira naturalmente.
     *                       Apos esse momento, o token e removido da blacklist automaticamente.
     */
    public void revogar(String jti, long expiraEmMillis) {
        if (jti == null || jti.trim().isEmpty()) {
            return;
        }
        tokensRevogados.put(jti.trim(), expiraEmMillis);
        limparExpiradosSeNecessario();
    }

    /**
     * Verifica se um JTI esta na blacklist.
     *
     * @param jti Identificador unico do token.
     * @return true se o token foi revogado e ainda nao expirou naturalmente.
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

        // Se o token ja expirou naturalmente, remove-lo da blacklist
        if (System.currentTimeMillis() > expira) {
            tokensRevogados.remove(jti.trim());
            return false;
        }

        return true;
    }

    /**
     * Limpa tokens expirados da blacklist para liberar memoria.
     * Executa no maximo uma vez por minuto para evitar overhead.
     */
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

    /**
     * Forca uma limpeza completa da blacklist (para testes).
     */
    public void limparTudo() {
        tokensRevogados.clear();
    }

    /**
     * Retorna o numero de tokens atualmente na blacklist (para monitoramento).
     */
    public int tamanho() {
        limparExpiradosSeNecessario();
        return tokensRevogados.size();
    }
}
