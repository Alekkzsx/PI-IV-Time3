// Desenvolvido por Guilherme Henrique Moreira
package utils;

import java.util.LinkedHashMap;
import java.util.Map;

// JSON simples para objetos com campos de texto, sem bibliotecas externas.
public final class JsonSimples {
    private JsonSimples() {}

    public static String escapar(String valor) {
        StringBuilder texto = new StringBuilder("\"");
        for (char c : valor.toCharArray()) {
            switch (c) {
                case '"': texto.append("\\\""); break;
                case '\\': texto.append("\\\\"); break;
                case '\n': texto.append("\\n"); break;
                case '\r': texto.append("\\r"); break;
                case '\t': texto.append("\\t"); break;
                default:
                    if (c < 32) texto.append(String.format("\\u%04x", (int)c));
                    else texto.append(c);
            }
        }
        return texto.append('"').toString();
    }

    public static String objeto(Map<String, String> campos) {
        StringBuilder texto = new StringBuilder("{");
        for (Map.Entry<String, String> campo : campos.entrySet()) {
            if (texto.length() > 1) texto.append(',');
            texto.append(escapar(campo.getKey())).append(':').append(escapar(campo.getValue()));
        }
        return texto.append('}').toString();
    }

    public static Map<String, String> analisar(String json) {
        Parser parser = new Parser(json);
        Map<String, String> resultado = parser.objeto();
        parser.espacos();
        if (parser.posicao != json.length()) throw new IllegalArgumentException("JSON com conteudo extra");
        return resultado;
    }

    private static final class Parser {
        private final String entrada;
        private int posicao;
        Parser(String entrada) { this.entrada = entrada; }
        void espacos() { while (posicao < entrada.length() && Character.isWhitespace(entrada.charAt(posicao))) posicao++; }
        boolean consumir(char esperado) {
            espacos();
            if (posicao < entrada.length() && entrada.charAt(posicao) == esperado) { posicao++; return true; }
            return false;
        }
        void exigir(char esperado) { if (!consumir(esperado)) throw new IllegalArgumentException("JSON invalido: esperado " + esperado); }
        String texto() {
            espacos(); exigir('"');
            StringBuilder resultado = new StringBuilder();
            while (posicao < entrada.length()) {
                char c = entrada.charAt(posicao++);
                if (c == '"') return resultado.toString();
                if (c == '\\') {
                    if (posicao >= entrada.length()) break;
                    char e = entrada.charAt(posicao++);
                    switch (e) {
                        case '"': resultado.append('"'); break;
                        case '\\': resultado.append('\\'); break;
                        case '/': resultado.append('/'); break;
                        case 'n': resultado.append('\n'); break;
                        case 'r': resultado.append('\r'); break;
                        case 't': resultado.append('\t'); break;
                        case 'b': resultado.append('\b'); break;
                        case 'f': resultado.append('\f'); break;
                        case 'u':
                            if (posicao + 4 > entrada.length()) throw new IllegalArgumentException("Unicode invalido");
                            try { resultado.append((char)Integer.parseInt(entrada.substring(posicao, posicao + 4), 16)); }
                            catch (NumberFormatException ex) { throw new IllegalArgumentException("Unicode invalido"); }
                            posicao += 4; break;
                        default: throw new IllegalArgumentException("Escape JSON invalido");
                    }
                } else {
                    if (c < 32) throw new IllegalArgumentException("Caractere de controle invalido");
                    resultado.append(c);
                }
            }
            throw new IllegalArgumentException("String JSON incompleta");
        }
        Map<String, String> objeto() {
            Map<String, String> campos = new LinkedHashMap<>();
            exigir('{');
            if (consumir('}')) return campos;
            do {
                String chave = texto(); exigir(':');
                if (campos.containsKey(chave)) throw new IllegalArgumentException("Campo repetido: " + chave);
                campos.put(chave, texto());
                if (consumir('}')) return campos;
                exigir(',');
                if (consumir('}')) throw new IllegalArgumentException("Virgula final invalida");
            } while (true);
        }
    }
}
