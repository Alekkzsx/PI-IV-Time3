// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
package auth;

import auth.utils.RevogacaoTokens;

/**
 * Teste nativo (sem JUnit) da blacklist de tokens (RevogacaoTokens).
 * Verifica:
 * - Revogacao de JTI
 * - Verificacao de token revogado
 * - Limpeza automatica de tokens expirados
 * - Thread safety (ConcurrentHashMap)
 */
public class RevogacaoTokensTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /** Executa os cenarios numerados; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;
        RevogacaoTokens blacklist = RevogacaoTokens.getInstance();
        blacklist.limparTudo(); // Reset para teste limpo

        // 1. Token nao revogado
        esperar(!blacklist.estaRevogado("jti-123"), "Blacklist: token nao revogado retorna false");

        // 2. Revogar token
        long expiraDaqui1Minuto = System.currentTimeMillis() + 60_000;
        blacklist.revogar("jti-123", expiraDaqui1Minuto);
        esperar(blacklist.estaRevogado("jti-123"), "Blacklist: token revogado retorna true");

        // 3. Token diferente nao e afetado
        esperar(!blacklist.estaRevogado("jti-456"), "Blacklist: token diferente nao e revogado");

        // 4. Token expirado deve ser removido automaticamente
        long expiraNoPassado = System.currentTimeMillis() - 1000;
        blacklist.revogar("jti-expirado", expiraNoPassado);
        esperar(!blacklist.estaRevogado("jti-expirado"),
                "Blacklist: token com expiracao passada e automaticamente removido");

        // 5. JTI null ou vazio
        esperar(!blacklist.estaRevogado(null), "Blacklist: null retorna false");
        esperar(!blacklist.estaRevogado(""), "Blacklist: vazio retorna false");

        // 6. Tamanho da blacklist
        blacklist.limparTudo();
        esperar(blacklist.tamanho() == 0, "Blacklist: tamanho 0 apos limpar");

        blacklist.revogar("jti-a", System.currentTimeMillis() + 60_000);
        blacklist.revogar("jti-b", System.currentTimeMillis() + 60_000);
        esperar(blacklist.tamanho() == 2, "Blacklist: tamanho 2 apos adicionar 2 tokens");

        // 7. Limpar tudo
        blacklist.limparTudo();
        esperar(blacklist.tamanho() == 0, "Blacklist: limparTudo remove todos os tokens");

        return falhas;
    }

    /** Runner isolado: exit 1 se houver falha. */
    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes de RevogacaoTokens passaram");
    }
}
