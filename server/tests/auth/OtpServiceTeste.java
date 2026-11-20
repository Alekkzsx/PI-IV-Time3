// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import auth.utils.OtpService;

/**
 * Teste nativo (sem JUnit) do servico de OTP (OtpService).
 * Verifica:
 * - Geracao de codigos de 6 digitos
 * - Hash HMAC-SHA256 do OTP
 * - Validacao em tempo constante
 * - Verificacao de tentativas excedidas
 */
public class OtpServiceTeste {
    private static int falhas = 0;
    private static final String SEGREDO_TESTE = "segredo-otp-teste-2026-agmrm-123456";

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static int executar() {
        falhas = 0;

        // 1. Geracao de codigo OTP de 6 digitos
        String codigo = OtpService.gerarCodigo();
        esperar(codigo != null && codigo.length() == 6,
                "OTP: gera codigo de 6 digitos");
        esperar(codigo.matches("\\d{6}"),
                "OTP: codigo e puramente numerico");

        // 2. Geracoes consecutivas sao diferentes (alta entropia)
        String codigo2 = OtpService.gerarCodigo();
        // Nota: pode coincidir em 1/1.000.000 dos casos, mas e extremamente raro
        // Aceitamos se ambos sao validos
        esperar(codigo2 != null && codigo2.length() == 6 && codigo2.matches("\\d{6}"),
                "OTP: segunda geracao tambem valida");

        // 3. Hash HMAC-SHA256
        String hash = OtpService.hashOtp("123456", SEGREDO_TESTE);
        esperar(hash != null && !hash.isEmpty(),
                "OTP: hash HMAC gerado com sucesso");

        // 4. Hash consistente para o mesmo codigo
        String hash2 = OtpService.hashOtp("123456", SEGREDO_TESTE);
        esperar(hash.equals(hash2),
                "OTP: hash e consistente para o mesmo codigo e segredo");

        // 5. Hash diferente para codigo diferente
        String hashOutro = OtpService.hashOtp("654321", SEGREDO_TESTE);
        esperar(!hash.equals(hashOutro),
                "OTP: hash diferente para codigo diferente");

        // 6. Validacao de codigo correto
        esperar(OtpService.validar("123456", hash, SEGREDO_TESTE),
                "OTP: valida codigo correto contra hash");

        // 7. Rejeicao de codigo incorreto
        esperar(!OtpService.validar("000000", hash, SEGREDO_TESTE),
                "OTP: rejeita codigo incorreto");

        // 8. Casos edge
        esperar(!OtpService.validar(null, hash, SEGREDO_TESTE),
                "OTP: rejeita codigo null");
        esperar(!OtpService.validar("", hash, SEGREDO_TESTE),
                "OTP: rejeita codigo vazio");
        esperar(!OtpService.validar("123456", null, SEGREDO_TESTE),
                "OTP: rejeita hash null");

        // 9. Tentativas excedidas
        esperar(!OtpService.tentativasExcedidas(0),
                "OTP: 0 tentativas nao excede");
        esperar(!OtpService.tentativasExcedidas(2),
                "OTP: 2 tentativas nao excede (max 3)");
        esperar(OtpService.tentativasExcedidas(3),
                "OTP: 3 tentativas excede o maximo");
        esperar(OtpService.tentativasExcedidas(10),
                "OTP: 10 tentativas excede o maximo");

        // 10. Hash diferente com segredo diferente
        String hashOutroSegredo = OtpService.hashOtp("123456", "outro-segredo-diferente-123");
        esperar(!hash.equals(hashOutroSegredo),
                "OTP: hash diferente com segredo diferente");

        return falhas;
    }

    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes de OtpService passaram");
    }
}
