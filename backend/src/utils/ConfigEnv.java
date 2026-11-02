// Desenvolvido por Marcelo Zarpelon

package utils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

// Le configuracoes das variaveis de ambiente ou de um arquivo env local.
public final class ConfigEnv {
    private static final Map<String, String> ARQUIVO = new HashMap<>();

    static {
        Path arquivo = procurarArquivo();
        if (arquivo != null) carregar(arquivo);
    }

    private ConfigEnv() {}

    // Procura o arquivo na pasta atual e na pasta acima (raiz do projeto).
    private static Path procurarArquivo() {
        for (String nome : new String[] {"env", ".env"}) {
            for (Path pasta : new Path[] {Path.of("."), Path.of("..")}) {
                Path candidato = pasta.resolve(nome);
                if (Files.isRegularFile(candidato)) return candidato;
            }
        }
        return null;
    }

    private static void carregar(Path arquivo) {
        try {
            for (String linha : Files.readAllLines(arquivo, StandardCharsets.UTF_8)) {
                String limpa = linha.trim();
                if (limpa.isEmpty() || limpa.startsWith("#")) continue;
                int igual = limpa.indexOf('=');
                if (igual <= 0) continue;
                ARQUIVO.put(limpa.substring(0, igual).trim(), limpa.substring(igual + 1).trim());
            }
        } catch (IOException e) {
            System.err.println("[CONFIG] Nao foi possivel ler " + arquivo + ": " + e.getMessage());
        }
    }

    // Variavel de ambiente tem prioridade sobre o arquivo.
    public static String obter(String chave, String padrao) {
        String valor = System.getenv(chave);
        if (valor == null || valor.isBlank()) valor = ARQUIVO.get(chave);
        return valor == null || valor.isBlank() ? padrao : valor;
    }

    public static String exigir(String chave) {
        String valor = obter(chave, null);
        if (valor == null) throw new IllegalStateException("Configuracao ausente: " + chave);
        return valor;
    }
}
