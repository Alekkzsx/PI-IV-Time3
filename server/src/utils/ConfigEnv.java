// Desenvolvido por Murillo Caravita - RA: 25014012
// Adaptado para Java SE puro (Java 8+)

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
    // Cache carregado uma unica vez: o .env e lido no carregamento da classe e nao muda em runtime.
    private static final Map<String, String> ARQUIVO = new HashMap<String, String>();
    // Caminho efetivamente carregado (exposto para diagnostico, ex.: email-diagnostic).
    private static Path ARQUIVO_ENV_CARREGADO = null;

    // Bloco estatico: qualquer primeira chamada a ConfigEnv ja ve o .env carregado.
    static {
        carregarEnvRaiz();
    }

    // Classe utilitaria estatica: construtor privado impede instanciacao.
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
     * Estrategias em ordem: (1) -Denv.file / ENV_FILE explicitos; (2) subida a partir do
     * working directory; (3) subida a partir do local do .class/jar; (4) fallbacks relativos.
     * Um candidato so e aceito se o diretorio tambem contem server/, backend/ ou .git,
     * evitando pegar um .env estranho de um diretorio pai nao relacionado.
     *
     * @return caminho absoluto do .env mestre ou null se nenhum candidato valido existir
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

    /** @return caminho do .env efetivamente carregado, ou null se a carga falhou/nao ocorreu. */
    public static Path getArquivoEnvCarregado() {
        return ARQUIVO_ENV_CARREGADO;
    }

    /**
     * Le o .env linha a linha no formato CHAVE=VALOR.
     * Ignora linhas vazias, comentarios (#) e linhas sem '='; valores vazios nao entram
     * no cache para que os fallbacks de obter() continuem funcionando.
     */
    private static void carregar(Path arquivo) {
        try {
            List<String> linhas = Files.readAllLines(arquivo, StandardCharsets.UTF_8);
            for (int i = 0; i < linhas.size(); i++) {
                String limpa = linhas.get(i).trim();
                if (limpa.isEmpty() || limpa.startsWith("#")) continue;
                int igual = limpa.indexOf('=');
                if (igual <= 0) continue;
                // Split apenas no PRIMEIRO '=': valores podem conter '=' (ex.: secrets Base64 com padding).
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

    /** Remove um par de aspas simples ou duplas que envolva todo o valor (estilo dotenv). */
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

    /**
     * Variavel de ambiente do SO ou propriedade JVM (-D) tem prioridade sobre o .env raiz.
     * Cadeia completa: getenv(chave) > getProperty(chave) > .env > alias equivalente > padrao.
     * Os aliases (AUTH_JWT_SECRET/JWT_SECRET e SMTP_SECURE/SMTP_SSL) garantem que Java e
     * backend TypeScript compartilhem o mesmo segredo/flag mesmo com nomes historicos diferentes.
     *
     * @param chave  nome da variavel procurada
     * @param padrao valor devolvido quando nenhuma fonte define a chave (pode ser null)
     * @return valor nao vazio e sem espacos nas pontas, ou o padrao
     */
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

    /** Versao inteira de obter(): valor ausente ou nao numerico cai silenciosamente no padrao. */
    public static int obterInteiro(String chave, int padrao) {
        String valor = obter(chave, null);
        if (valor == null) return padrao;
        try {
            return Integer.parseInt(valor);
        } catch (NumberFormatException e) {
            return padrao;
        }
    }

    /**
     * Obtem uma configuracao obrigatoria; ausente = erro de boot imediato (fail-fast),
     * usado para segredos que nao podem ter fallback inseguro (ex.: JWT).
     *
     * @throws IllegalStateException se a chave nao estiver definida em nenhuma fonte
     */
    public static String exigir(String chave) {
        String valor = obter(chave, null);
        if (valor == null) {
            throw new IllegalStateException("Configuracao ausente: " + chave);
        }
        return valor;
    }
}
