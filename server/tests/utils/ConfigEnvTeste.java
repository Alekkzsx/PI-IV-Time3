// Desenvolvido por Marcelo Zarpelon e Alex Gabriel Soares Sousa
package utils;

import java.nio.file.Files;
import java.nio.file.Path;

public class ConfigEnvTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

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
        esperar(jwtSecret != null && jwtSecret.equals(jwtSecretAlias),
                "ConfigEnv: alias JWT_SECRET e AUTH_JWT_SECRET sincronizados");

        return falhas;
    }
}

