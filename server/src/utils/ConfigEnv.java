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
 * Leitor nativo de configuracoes a partir de variaveis de ambiente ou arquivos .env locais,
 * sem nenhuma biblioteca externa.
 */
public final class ConfigEnv {
    private static final Map<String, String> ARQUIVO = new HashMap<String, String>();

    static {
        carregarPadroes();
    }

    private ConfigEnv() {}

    private static void carregarPadroes() {
        String[] pastas = new String[] { ".", "..", "../backend" };
        String[] nomes = new String[] { ".env.local", ".env", "env" };
        for (int p = 0; p < pastas.length; p++) {
            for (int n = 0; n < nomes.length; n++) {
                Path candidato = Paths.get(pastas[p], nomes[n]);
                if (Files.isRegularFile(candidato)) {
                    carregar(candidato);
                }
            }
        }
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
                if (!ARQUIVO.containsKey(chave) && !valor.isEmpty()) {
                    ARQUIVO.put(chave, valor);
                }
            }
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

    /** Variavel de ambiente do SO ou propriedade JVM (-D) tem prioridade sobre arquivos .env locais. */
    public static String obter(String chave, String padrao) {
        String valor = System.getenv(chave);
        if (valor == null || valor.trim().isEmpty()) {
            valor = System.getProperty(chave);
        }
        if (valor == null || valor.trim().isEmpty()) {
            valor = ARQUIVO.get(chave);
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
