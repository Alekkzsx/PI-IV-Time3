// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

package utils;

import java.util.LinkedHashMap;
import java.util.Map;

// JSON simples para objetos com campos de texto, sem bibliotecas externas.
/**
 * Subconjunto minimalista de JSON: apenas objetos planos {chave: "texto"}.
 * Usado onde o payload e garantidamente string->string (ex.: respostas curtas de auth);
 * para estruturas aninhadas/numericas use {@link Json}.
 * escapar() tambem e reaproveitado pelo serializador completo Json.
 */
public final class JsonSimples {
    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private JsonSimples() {}

    /**
     * Escapa e envolve um texto em aspas duplas seguindo a RFC 8259:
     * aspas, barra invertida e controles comuns ganham escape curto; demais
     * caracteres < 32 viram \\u00XX. null vira o literal null (sem aspas).
     */
    public static String escapar(String valor) {
        if (valor == null) return "null";
        StringBuilder texto = new StringBuilder("\"");
        for (char c : valor.toCharArray()) {
            switch (c) {
                case '"': texto.append("\\\""); break;
                case '\\': texto.append("\\\\"); break;
                case '\n': texto.append("\\n"); break;
                case '\r': texto.append("\\r"); break;
                case '\t': texto.append("\\t"); break;
                case '\b': texto.append("\\b"); break;
                case '\f': texto.append("\\f"); break;
                default:
                    // Controle sem escape curto dedicado: forma hexadecimal obrigatoria \\u00XX.
                    if (c < 32) texto.append(String.format("\\u%04x", (int) c));
                    else texto.append(c);
            }
        }
        return texto.append('"').toString();
    }

    /** Serializa um mapa plano como objeto JSON, escapando chaves e valores. */
    public static String objeto(Map<String, String> campos) {
        StringBuilder texto = new StringBuilder("{");
        for (Map.Entry<String, String> campo : campos.entrySet()) {
            if (texto.length() > 1) texto.append(',');
            texto.append(escapar(campo.getKey())).append(':').append(escapar(campo.getValue()));
        }
        return texto.append('}').toString();
    }

    /**
     * Analisa um objeto JSON plano de textos.
     *
     * @throws IllegalArgumentException se houver sintaxe invalida, campo repetido ou sobra de conteudo
     */
    public static Map<String, String> analisar(String json) {
        if (json == null) throw new IllegalArgumentException("JSON vazio");
        Parser parser = new Parser(json);
        Map<String, String> resultado = parser.objeto();
        parser.espacos();
        if (parser.posicao != json.length()) throw new IllegalArgumentException("JSON com conteudo extra");
        return resultado;
    }

    /** Cursor de leitura especializado na gramatica reduzida {string: string, ...}. */
    private static final class Parser {
        private final String entrada;
        private int posicao;

        Parser(String entrada) {
            this.entrada = entrada;
        }

        /** Avanca o cursor sobre espacos em branco entre tokens. */
        void espacos() {
            while (posicao < entrada.length() && Character.isWhitespace(entrada.charAt(posicao))) {
                posicao++;
            }
        }

        /** Consome o caractere se for o esperado; devolve false sem avancar caso contrario (lookahead). */
        boolean consumir(char esperado) {
            espacos();
            if (posicao < entrada.length() && entrada.charAt(posicao) == esperado) {
                posicao++;
                return true;
            }
            return false;
        }

        /** Versao estrita de consumir(): ausencia do caractere estrutural invalida o JSON. */
        void exigir(char esperado) {
            if (!consumir(esperado)) {
                throw new IllegalArgumentException("JSON invalido: esperado " + esperado);
            }
        }

        /** Le string entre aspas com os mesmos escapes da RFC 8259 aceitos por Json. */
        String texto() {
            espacos();
            exigir('"');
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
                            try {
                                resultado.append((char) Integer.parseInt(entrada.substring(posicao, posicao + 4), 16));
                            } catch (NumberFormatException ex) {
                                throw new IllegalArgumentException("Unicode invalido");
                            }
                            posicao += 4;
                            break;
                        default:
                            throw new IllegalArgumentException("Escape JSON invalido");
                    }
                } else {
                    if (c < 32) throw new IllegalArgumentException("Caractere de controle invalido");
                    resultado.append(c);
                }
            }
            throw new IllegalArgumentException("String JSON incompleta");
        }

        /** Le o objeto plano; rejeita chave repetida e virgula final (trailing comma), ambos fora da RFC. */
        Map<String, String> objeto() {
            Map<String, String> campos = new LinkedHashMap<String, String>();
            exigir('{');
            if (consumir('}')) return campos;
            do {
                String chave = texto();
                exigir(':');
                if (campos.containsKey(chave)) throw new IllegalArgumentException("Campo repetido: " + chave);
                campos.put(chave, texto());
                if (consumir('}')) return campos;
                exigir(',');
                if (consumir('}')) throw new IllegalArgumentException("Virgula final invalida");
            } while (true);
        }
    }
}
