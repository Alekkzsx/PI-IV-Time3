// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Blacklist de tokens revogados em memoria (ConcurrentHashMap) com limpeza automatica.
 */
public final class RevogacaoTokens {
    private static final RevogacaoTokens INSTANCIA = new RevogacaoTokens();
    private static final long INTERVALO_LIMPEZA_MS = 60_000;

    private final ConcurrentHashMap<String, Long> tokensRevogados = new ConcurrentHashMap<String, Long>();
    private volatile long ultimaLimpeza = System.currentTimeMillis();

    private RevogacaoTokens() {}

    public static RevogacaoTokens getInstance() {
        return INSTANCIA;
    }

    public void revogar(String jti, long expiraEmMillis) {
        if (jti == null || jti.trim().isEmpty()) {
            return;
        }
        tokensRevogados.put(jti.trim(), expiraEmMillis);
        limparExpiradosSeNecessario();
    }

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

    public void limparTudo() {
        tokensRevogados.clear();
    }

    public int tamanho() {
        limparExpiradosSeNecessario();
        return tokensRevogados.size();
    }
}
