// Desenvolvido por Time 3 AGMRM — PI-IV (PUC-Campinas 2026)
// Equipe: Alex Gabriel (24802449), Guilherme Moreira (25006702),
//         Marcelo Zarpelon (25015323), Murillo Caravita (25014012), Rafael Inacio (25009719)

import auth.utils.BCrypt;
import auth.utils.SenhaHasher;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Teste Unitario INTRACLASSE — Classe de Dominio: {@link SenhaHasher}.
 *
 * Abordagem de Particionamento Adotada: PARTICIONAMENTO POR CATEGORIAS DE METODOS.
 * Justificativa: Classe utilitaria stateless que concentra calculos criptograficos
 * e validacoes agrupadas em 3 categorias:
 *   - Categoria 1 (Geracao Criptografica): hash(String), hashDummy()
 *   - Categoria 2 (Verificacao em Tempo Constante): verificar(String, String) [PBKDF2 + BCrypt]
 *   - Categoria 3 (Politica de Complexidade): validarComplexidade(...) + ResultadoValidacao
 */
@DisplayName("Intraclasse [CATEGORIAS DE METODOS] — SenhaHasher")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class IntraclasseSenhaHasherTest {

    @Test
    @Order(1)
    @DisplayName("Cat 1 [GERACAO]: Gera hash PBKDF2-SHA256 (600k) com salt unico e rejeita senha vazia")
    void cat1GeracaoHashPbkdf2EDummy() {
        String h1 = SenhaHasher.hash("Agmrm@2026!");
        String h2 = SenhaHasher.hash("Agmrm@2026!");

        assertNotNull(h1);
        String[] partes = h1.split(":");
        assertEquals(3, partes.length, "Formato deve ser iteracoes:saltBase64:hashBase64");
        assertEquals("600000", partes[0], "Custo OWASP 2023 deve ser 600.000 iteracoes");
        assertNotEquals(h1, h2, "Salt aleatorio deve produzir hashes distintos para a mesma senha");

        String dummy = SenhaHasher.hashDummy();
        assertTrue(dummy.startsWith("600000:"), "hashDummy() deve manter mesmo custo PBKDF2");
        assertFalse(SenhaHasher.verificar("Agmrm@2026!", dummy));

        assertThrows(IllegalArgumentException.class, () -> SenhaHasher.hash(null));
        assertThrows(IllegalArgumentException.class, () -> SenhaHasher.hash(""));
    }

    @Test
    @Order(2)
    @DisplayName("Cat 2 [VERIFICACAO]: Valida PBKDF2, BCrypt legado ($2a$) e rejeita hashes malformados")
    void cat2VerificacaoPbkdf2BCryptEMalformados() {
        String hashPbkdf2 = SenhaHasher.hash("SenhaForte#99");
        assertTrue(SenhaHasher.verificar("SenhaForte#99", hashPbkdf2));
        assertFalse(SenhaHasher.verificar("SenhaErrada#99", hashPbkdf2));

        String hashBcrypt = BCrypt.hashpw("Legado@2026", BCrypt.gensalt(4));
        assertTrue(hashBcrypt.startsWith("$2a$"));
        assertTrue(SenhaHasher.verificar("Legado@2026", hashBcrypt));
        assertFalse(SenhaHasher.verificar("OutraSenha", hashBcrypt));

        assertFalse(SenhaHasher.verificar(null, hashPbkdf2));
        assertFalse(SenhaHasher.verificar("abc", null));
        assertFalse(SenhaHasher.verificar("abc", ""));
        assertFalse(SenhaHasher.verificar("abc", "formato-invalido-sem-dois-pontos"));
        assertFalse(SenhaHasher.verificar("abc", "naoNumero:AAAA:BBBB"));
        assertFalse(SenhaHasher.verificar("abc", "500:AAAA:BBBB"), "Iteracoes < 1000 devem ser rejeitadas");
        assertFalse(SenhaHasher.verificar("abc", "600000:%%%base64invalido%%%:BBBB"));
    }

    @Test
    @Order(3)
    @DisplayName("Cat 3 [POLITICA DE COMPLEXIDADE]: Valida regras de tamanho, caixa, digito, especial e Unicode")
    void cat3ValidacaoComplexidade() {
        SenhaHasher.ResultadoValidacao ok = SenhaHasher.validarComplexidade(
                "Agmrm@2026", 8, 64, true, true, true, true);
        assertTrue(ok.isValido());
        assertEquals("Senha valida.", ok.getMensagem());

        assertFalse(SenhaHasher.validarComplexidade("", 8, 64, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("Ab1@", 8, 64, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("A1@aaaaaaaa", 8, 8, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("agmrm@2026", 8, 64, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("AGMRM@2026", 8, 64, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("Agmrm@Pucc", 8, 64, true, true, true, true).isValido());
        assertFalse(SenhaHasher.validarComplexidade("Agmrm2026", 8, 64, true, true, true, true).isValido());

        SenhaHasher.ResultadoValidacao unicodeOk = SenhaHasher.validarComplexidade(
                "Águia@2026ç", 8, 64, true, true, true, true);
        assertTrue(unicodeOk.isValido(), "Character.isUpperCase/isLowerCase suporta acentuacao PT-BR");
    }

    @Test
    @Order(4)
    @DisplayName("Cat 2/3 [DETECCAO DE ANOMALIAS #4 e #5]: Hash BCrypt corrompido lanca excecao e espaco passa como especial")
    void cat4EvidenciaAnomaliasSenhaHasher() {
        assertThrows(RuntimeException.class,
                () -> SenhaHasher.verificar("Senha@123", "$2a$corrompido"),
                "Evidencia da Anomalia #4: BCrypt.checkpw lanca RuntimeException sem try/catch em SenhaHasher.verificar");

        SenhaHasher.ResultadoValidacao comEspaco = SenhaHasher.validarComplexidade(
                "Agmrm2026 ", 8, 64, true, true, true, true);
        assertTrue(comEspaco.isValido(),
                "Evidencia da Anomalia #5: espaco em branco e aceito como caractere especial");
    }
}
