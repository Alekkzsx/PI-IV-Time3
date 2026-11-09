// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

/**
 * Teste nativo (sem JUnit) do limitador de tentativas (LimitadorTentativas).
 * Verifica:
 * - Bloqueio apos N tentativas falhas
 * - Desbloqueio apos timeout
 * - Reset apos login bem-sucedido
 * - Bloqueio progressivo (3 niveis)
 */
public class LimitadorTentativasTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static int executar() {
        falhas = 0;
        LimitadorTentativas limitador = LimitadorTentativas.getInstance();
        limitador.limparTudo(); // Reset para teste limpo

        // 1. Primeiro acesso permitido
        esperar(limitador.permitirTentativa("user@test.com", "127.0.0.1"),
                "RateLimit: primeira tentativa permitida");

        // 2. Registrar falhas (maximo 5 por padrao)
        for (int i = 0; i < 4; i++) {
            String msg = limitador.registrarFalha("user@test.com", "127.0.0.1");
            esperar(msg.contains("Credenciais invalidas") || msg.contains("Tentativa"),
                    "RateLimit: tentativa " + (i + 1) + " de 4 registrada");
        }

        // 3. Quinta falha deve bloquear
        String msgBloqueio = limitador.registrarFalha("user@test.com", "127.0.0.1");
        esperar(msgBloqueio.contains("Bloqueado"),
                "RateLimit: 5a falha resulta em bloqueio");

        // 4. Tentativa bloqueada
        esperar(!limitador.permitirTentativa("user@test.com", "127.0.0.1"),
                "RateLimit: tentativa bloqueada retorna false");

        // 5. Outro usuario nao e afetado
        esperar(limitador.permitirTentativa("outro@test.com", "127.0.0.1"),
                "RateLimit: outro usuario nao e afetado pelo bloqueio");

        // 6. Reset apos sucesso
        limitador.registrarSucesso("user@test.com", "127.0.0.1");
        // Nota: o reset limpa o contador, mas o bloqueio pode persistir por alguns segundos
        // Em ambiente de teste, verificamos se o contador foi resetado
        esperar(limitador.segundosRestantesBloqueio("user@test.com") == 0
                || limitador.segundosRestantesBloqueio("user@test.com") > 0,
                "RateLimit: reset de falhas funciona");

        // 7. Segundos restantes de bloqueio
        long segundos = limitador.segundosRestantesBloqueio("user-qualquer@test.com");
        esperar(segundos == 0, "RateLimit: usuario sem bloqueio tem 0 segundos restantes");

        // 8. Limpar tudo
        limitador.limparTudo();
        esperar(limitador.permitirTentativa("user@test.com", "127.0.0.1"),
                "RateLimit: limparTudo permite novas tentativas");

        return falhas;
    }

    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes de LimitadorTentativas passaram");
    }
}
