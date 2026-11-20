// Desenvolvido por Murillo Caravita - RA: 25014012
package utils;

import java.nio.file.Files;
import java.nio.file.Path;

/**
 * Suite do ConfigEnv: garante que o .env MESTRE da raiz foi localizado/carregado e que
 * as chaves criticas (SERVER_PORT, MONGODB_DATABASE, segredo JWT e seu alias) resolvem
 * com os valores esperados. Depende do .env real do projeto (teste de integracao leve).
 */
public class ConfigEnvTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /** Executa os cenarios da suite; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;

        Path arquivoEnv = ConfigEnv.getArquivoEnvCarregado();
        esperar(arquivoEnv != null && Files.isRegularFile(arquivoEnv),
                "ConfigEnv: arquivo .env mestre carregado da raiz do projeto");
        esperar(arquivoEnv != null && arquivoEnv.toString().endsWith(".env"),
                "ConfigEnv: nome do arquivo e exatamente '.env'");

        String porta = ConfigEnv.obter("SERVER_PORT", "8080");
        esperar("8080".equals(porta), "ConfigEnv: SERVER_PORT configurado como 8080");

        String db = ConfigEnv.obter("MONGODB_DATABASE", null);
        esperar("agmrm".equals(db), "ConfigEnv: MONGODB_DATABASE carregado como 'agmrm'");

        String jwtSecret = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        esperar(jwtSecret != null && jwtSecret.length() >= 32,
                "ConfigEnv: AUTH_JWT_SECRET carregado com segredo robusto (>=32 chars)");

        String jwtSecretAlias = ConfigEnv.obter("JWT_SECRET", null);
        // Alias interoperavel: Java e backend TS precisam enxergar o MESMO segredo.
        esperar(jwtSecret != null && jwtSecret.equals(jwtSecretAlias),
                "ConfigEnv: alias JWT_SECRET e AUTH_JWT_SECRET sincronizados");

        return falhas;
    }
}

