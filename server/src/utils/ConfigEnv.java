// Desenvolvido por Marcelo Zarpelon e adaptado para Java SE puro (Java 8+)

package utils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Leitor nativo de configuracoes a partir de variaveis de ambiente ou exclusivamente do
 * arquivo .env mestre na raiz do projeto (c:\Users\...\PI-IV-Time3\.env),
 * sem nenhuma biblioteca externa.
 */
public final class ConfigEnv {
    private static final Map<String, String> ARQUIVO = new HashMap<String, String>();
    private static Path ARQUIVO_ENV_CARREGADO = null;

    static {
        carregarEnvRaiz();
    }

    private ConfigEnv() {}

    /**
     * Localiza e carrega EXCLUSIVAMENTE o arquivo .env mestre localizado na raiz do projeto.
     */
    private static void carregarEnvRaiz() {
        Path arquivoEnv = localizarArquivoEnvRaiz();
        if (arquivoEnv != null && Files.isRegularFile(arquivoEnv)) {
            ARQUIVO_ENV_CARREGADO = arquivoEnv;
            carregar(arquivoEnv);
        } else {
            System.err.println("[CONFIG] AVISO: Arquivo .env da raiz nao encontrado.");
        }
    }

    /**
     * Localiza confiavelmente o arquivo .env da raiz do projeto subindo a arvore de diretorios.
     */
    public static Path localizarArquivoEnvRaiz() {
        // 1. Propriedade explícita da JVM (-Denv.file=...) ou variável de ambiente ENV_FILE
        String envProp = System.getProperty("env.file");
        if (envProp != null && !envProp.trim().isEmpty()) {
            Path p = Paths.get(envProp.trim()).toAbsolutePath().normalize();
            if (Files.isRegularFile(p)) return p;
        }
        String envVar = System.getenv("ENV_FILE");
        if (envVar != null && !envVar.trim().isEmpty()) {
            Path p = Paths.get(envVar.trim()).toAbsolutePath().normalize();
            if (Files.isRegularFile(p)) return p;
        }

        // 2. Busca subindo a partir do diretorio de trabalho atual (working directory)
        Path cursor = Paths.get(".").toAbsolutePath().normalize();
        while (cursor != null) {
            Path candidato = cursor.resolve(".env");
            if (Files.isRegularFile(candidato)) {
                // Confirma que e a raiz do projeto atraves da presenca dos modulos principais
                if (Files.isDirectory(cursor.resolve("server")) ||
                    Files.isDirectory(cursor.resolve("backend")) ||
                    Files.isDirectory(cursor.resolve(".git"))) {
                    return candidato;
                }
            }
            cursor = cursor.getParent();
        }

        // 3. Busca subindo a partir da localizacao do proprio codigo compilado / classe
        try {
            Path codeSource = Paths.get(ConfigEnv.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toAbsolutePath().normalize();
            cursor = codeSource;
            while (cursor != null) {
                Path candidato = cursor.resolve(".env");
                if (Files.isRegularFile(candidato)) {
                    if (Files.isDirectory(cursor.resolve("server")) ||
                        Files.isDirectory(cursor.resolve("backend")) ||
                        Files.isDirectory(cursor.resolve(".git"))) {
                        return candidato;
                    }
                }
                cursor = cursor.getParent();
            }
        } catch (Exception ignored) {
            // Ignorado em ambientes restritos de classloader
        }

        // 4. Fallback relativo padrao para a raiz (quando executado a partir de server/)
        Path relativoServer = Paths.get("..", ".env").toAbsolutePath().normalize();
        if (Files.isRegularFile(relativoServer)) {
            return relativoServer;
        }

        Path relativoRaiz = Paths.get(".env").toAbsolutePath().normalize();
        if (Files.isRegularFile(relativoRaiz)) {
            return relativoRaiz;
        }

        return null;
    }

    public static Path getArquivoEnvCarregado() {
        return ARQUIVO_ENV_CARREGADO;
    }

    private static void carregar(Path arquivo) {
        try {
            List<String> linhas = Files.readAllLines(arquivo, StandardCharsets.UTF_8);
            for (int i = 0; i < linhas.size(); i++) {
                String limpa = linhas.get(i).trim();
                if (limpa.isEmpty() || limpa.startsWith("#")) continue;
                int igual = limpa.indexOf('=');
                if (igual <= 0) continue;
                String chave = limpa.substring(0, igual).trim();
                String valor = limparAspas(limpa.substring(igual + 1).trim());
                if (!chave.isEmpty() && !valor.isEmpty()) {
                    ARQUIVO.put(chave, valor);
                }
            }
            System.out.println("[CONFIG] Variaveis carregadas com sucesso do .env mestre: " + arquivo);
        } catch (IOException e) {
            System.err.println("[CONFIG] Nao foi possivel ler " + arquivo + ": " + e.getMessage());
        }
    }

    private static String limparAspas(String valor) {
        if (valor.length() >= 2) {
            char inicio = valor.charAt(0);
            char fim = valor.charAt(valor.length() - 1);
            if ((inicio == '"' && fim == '"') || (inicio == '\'' && fim == '\'')) {
                return valor.substring(1, valor.length() - 1);
            }
        }
        return valor;
    }

    /** Variavel de ambiente do SO ou propriedade JVM (-D) tem prioridade sobre o .env raiz. */
    public static String obter(String chave, String padrao) {
        String valor = System.getenv(chave);
        if (valor == null || valor.trim().isEmpty()) {
            valor = System.getProperty(chave);
        }
        if (valor == null || valor.trim().isEmpty()) {
            valor = ARQUIVO.get(chave);
        }

        // Interoperabilidade transparente entre chaves equivalentes
        if (valor == null || valor.trim().isEmpty()) {
            if ("AUTH_JWT_SECRET".equals(chave)) {
                valor = obter("JWT_SECRET", null);
            } else if ("JWT_SECRET".equals(chave)) {
                valor = obter("AUTH_JWT_SECRET", null);
            } else if ("SMTP_SECURE".equals(chave)) {
                valor = obter("SMTP_SSL", null);
            } else if ("SMTP_SSL".equals(chave)) {
                valor = obter("SMTP_SECURE", null);
            }
        }

        return (valor == null || valor.trim().isEmpty()) ? padrao : valor.trim();
    }

    public static int obterInteiro(String chave, int padrao) {
        String valor = obter(chave, null);
        if (valor == null) return padrao;
        try {
            return Integer.parseInt(valor);
        } catch (NumberFormatException e) {
            return padrao;
        }
    }

    public static String exigir(String chave) {
        String valor = obter(chave, null);
        if (valor == null) {
            throw new IllegalStateException("Configuracao ausente: " + chave);
        }
        return valor;
    }
}
