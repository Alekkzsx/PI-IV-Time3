// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import auth.utils.BCrypt;
import auth.utils.SenhaHasher;

/**
 * Teste nativo (sem JUnit) do SenhaHasher com PBKDF2WithHmacSHA256.
 * Verifica:
 * - Hash e verificacao de senhas
 * - Rejeicao de senhas incorretas
 * - Protecao contra timing attacks (MessageDigest.isEqual)
 * - Hash dummy (mesmo custo computacional)
 * - Validacao de complexidade de senha
 */
public class SenhaHasherTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /** Executa os cenarios numerados; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;

        // 1. Hash e verificacao de senha valida
        String hash = SenhaHasher.hash("MinhaSenha@123");
        esperar(hash != null && hash.contains(":"), "PBKDF2: gera hash no formato iteracoes:salt:hash");
        esperar(SenhaHasher.verificar("MinhaSenha@123", hash), "PBKDF2: verifica senha correta");
        esperar(!SenhaHasher.verificar("SenhaErrada@123", hash), "PBKDF2: rejeita senha incorreta");

        // 2. Hashes diferentes para a mesma senha (salt aleatorio)
        String hash2 = SenhaHasher.hash("MinhaSenha@123");
        esperar(!hash.equals(hash2), "PBKDF2: salt aleatorio gera hashes diferentes para a mesma senha");
        esperar(SenhaHasher.verificar("MinhaSenha@123", hash2), "PBKDF2: hash2 tambem verifica corretamente");

        // 3. Hash dummy (protecao contra enumeracao)
        String dummy = SenhaHasher.hashDummy();
        esperar(dummy != null && dummy.contains(":"), "PBKDF2: hash dummy gerado no formato correto");
        esperar(!SenhaHasher.verificar("qualquer-coisa", dummy), "PBKDF2: hash dummy nunca valida");

        // 4. Casos edge
        esperar(!SenhaHasher.verificar(null, hash), "PBKDF2: rejeita senha null");
        esperar(!SenhaHasher.verificar("", hash), "PBKDF2: rejeita senha vazia");
        esperar(!SenhaHasher.verificar("senha", null), "PBKDF2: rejeita hash null");
        esperar(!SenhaHasher.verificar("senha", ""), "PBKDF2: rejeita hash vazio");
        esperar(!SenhaHasher.verificar("senha", "malformado"), "PBKDF2: rejeita hash malformado");

        // 5. Hash com iteracoes suspeitas
        String hashIteracoesBaixas = "100:YWJjZGVmZ2hpamtsbW5v:cXdlcnR5dWlvcGFzZGZnaGprbHp4Y3Zibm0=";
        esperar(!SenhaHasher.verificar("qualquer", hashIteracoesBaixas),
                "PBKDF2: rejeita hash com iteracoes < 1000");

        // 6. Validacao de hashes BCrypt (compatibilidade com seed e banco de dados existente)
        // Hash bcrypt real de 'Agmrm@2026' gerado pelo bcryptjs (custo 12)
        String hashBcrypt = "$2b$12$c5Xo4mz.L7fRyg3UwssNBOmSoU6Rdm2S0c.e0enR7VMmZL/tdaGVy";
        esperar(BCrypt.checkpw("Agmrm@2026", hashBcrypt), "BCrypt: valida senha correta via BCrypt.checkpw");
        esperar(SenhaHasher.verificar("Agmrm@2026", hashBcrypt), "BCrypt: SenhaHasher.verificar() valida hash $2b$12$");
        esperar(!SenhaHasher.verificar("SenhaErrada", hashBcrypt), "BCrypt: SenhaHasher.verificar() rejeita senha errada em hash $2b$12$");

        // 7. Validacao de complexidade (limites explicitos para independencia do .env local)
        SenhaHasher.ResultadoValidacao r1 = SenhaHasher.validarComplexidade("Fraca", 8, 128, true, true, true, true);
        esperar(!r1.isValido(), "Complexidade: rejeita senha muito curta e fraca");

        SenhaHasher.ResultadoValidacao r2 = SenhaHasher.validarComplexidade("senha123", 8, 128, true, true, true, true);
        esperar(!r2.isValido(), "Complexidade: rejeita senha sem maiuscula e sem especial");

        SenhaHasher.ResultadoValidacao r3 = SenhaHasher.validarComplexidade("SenhaForte@2026", 8, 128, true, true, true, true);
        esperar(r3.isValido(), "Complexidade: aceita senha forte com todos os criterios");

        SenhaHasher.ResultadoValidacao r4 = SenhaHasher.validarComplexidade(null, 8, 128, true, true, true, true);
        esperar(!r4.isValido(), "Complexidade: rejeita senha null");

        SenhaHasher.ResultadoValidacao r5 = SenhaHasher.validarComplexidade("", 8, 128, true, true, true, true);
        esperar(!r5.isValido(), "Complexidade: rejeita senha vazia");

        return falhas;
    }

    /** Runner isolado: exit 1 se houver falha. */
    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes de SenhaHasher passaram");
    }
}
