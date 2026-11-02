// Desenvolvido por Marcelo Zarpelon

package utils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// JSON completo escrito a mao: objetos, listas, textos, numeros, booleanos e nulo.
// Objeto -> Map<String, Object>, lista -> List<Object>, numero -> Long ou Double.
public final class Json {
    private static final int PROFUNDIDADE_MAXIMA = 32;

    private Json() {}

    public static Object analisar(String json) {
        if (json == null) throw new IllegalArgumentException("JSON vazio");
        Leitor leitor = new Leitor(json);
        Object valor = leitor.valor(0);
        leitor.espacos();
        if (leitor.posicao != json.length()) throw new IllegalArgumentException("JSON com conteudo extra");
        return valor;
    }

    @SuppressWarnings("unchecked")
    public static Map<String, Object> analisarObjeto(String json) {
        Object valor = analisar(json);
        if (!(valor instanceof Map)) throw new IllegalArgumentException("JSON deve ser um objeto");
        return (Map<String, Object>) valor;
    }

    public static String escrever(Object valor) {
        StringBuilder texto = new StringBuilder();
        escrever(valor, texto);
        return texto.toString();
    }

    private static void escrever(Object valor, StringBuilder texto) {
        if (valor == null) { texto.append("null"); return; }
        if (valor instanceof String) { texto.append(JsonSimples.escapar((String) valor)); return; }
        if (valor instanceof Boolean || valor instanceof Integer || valor instanceof Long) { texto.append(valor); return; }
        if (valor instanceof Double || valor instanceof Float) {
            double numero = ((Number) valor).doubleValue();
            if (Double.isNaN(numero) || Double.isInfinite(numero)) throw new IllegalArgumentException("Numero invalido");
            texto.append(numero);
            return;
        }
        if (valor instanceof Map) {
            texto.append('{');
            boolean primeiro = true;
            for (Map.Entry<?, ?> campo : ((Map<?, ?>) valor).entrySet()) {
                if (!primeiro) texto.append(',');
                primeiro = false;
                texto.append(JsonSimples.escapar(String.valueOf(campo.getKey()))).append(':');
                escrever(campo.getValue(), texto);
            }
            texto.append('}');
            return;
        }
        if (valor instanceof Iterable) {
            texto.append('[');
            boolean primeiro = true;
            for (Object item : (Iterable<?>) valor) {
                if (!primeiro) texto.append(',');
                primeiro = false;
                escrever(item, texto);
            }
            texto.append(']');
            return;
        }
        throw new IllegalArgumentException("Tipo nao suportado em JSON: " + valor.getClass().getSimpleName());
    }

    private static final class Leitor {
        private final String entrada;
        private int posicao;

        Leitor(String entrada) { this.entrada = entrada; }

        void espacos() {
            while (posicao < entrada.length() && Character.isWhitespace(entrada.charAt(posicao))) posicao++;
        }

        char proximo() {
            espacos();
            if (posicao >= entrada.length()) throw new IllegalArgumentException("JSON incompleto");
            return entrada.charAt(posicao);
        }

        void exigir(char esperado) {
            if (proximo() != esperado) throw new IllegalArgumentException("JSON invalido: esperado " + esperado);
            posicao++;
        }

        Object valor(int nivel) {
            if (nivel > PROFUNDIDADE_MAXIMA) throw new IllegalArgumentException("JSON muito profundo");
            char c = proximo();
            if (c == '{') return objeto(nivel);
            if (c == '[') return lista(nivel);
            if (c == '"') return texto();
            if (c == 't') { literal("true"); return Boolean.TRUE; }
            if (c == 'f') { literal("false"); return Boolean.FALSE; }
            if (c == 'n') { literal("null"); return null; }
            return numero();
        }

        void literal(String esperado) {
            if (!entrada.startsWith(esperado, posicao)) throw new IllegalArgumentException("JSON invalido");
            posicao += esperado.length();
        }

        Map<String, Object> objeto(int nivel) {
            Map<String, Object> campos = new LinkedHashMap<>();
            exigir('{');
            if (proximo() == '}') { posicao++; return campos; }
            while (true) {
                String chave = texto();
                exigir(':');
                if (campos.containsKey(chave)) throw new IllegalArgumentException("Campo repetido: " + chave);
                campos.put(chave, valor(nivel + 1));
                char c = proximo();
                posicao++;
                if (c == '}') return campos;
                if (c != ',') throw new IllegalArgumentException("JSON invalido: esperado , ou }");
            }
        }

        List<Object> lista(int nivel) {
            List<Object> itens = new ArrayList<>();
            exigir('[');
            if (proximo() == ']') { posicao++; return itens; }
            while (true) {
                itens.add(valor(nivel + 1));
                char c = proximo();
                posicao++;
                if (c == ']') return itens;
                if (c != ',') throw new IllegalArgumentException("JSON invalido: esperado , ou ]");
            }
        }

        String texto() {
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
                            try { resultado.append((char) Integer.parseInt(entrada.substring(posicao, posicao + 4), 16)); }
                            catch (NumberFormatException ex) { throw new IllegalArgumentException("Unicode invalido"); }
                            posicao += 4;
                            break;
                        default: throw new IllegalArgumentException("Escape JSON invalido");
                    }
                } else {
                    if (c < 32) throw new IllegalArgumentException("Caractere de controle invalido");
                    resultado.append(c);
                }
            }
            throw new IllegalArgumentException("String JSON incompleta");
        }

        Object numero() {
            int inicio = posicao;
            if (posicao < entrada.length() && entrada.charAt(posicao) == '-') posicao++;
            boolean decimal = false;
            while (posicao < entrada.length()) {
                char c = entrada.charAt(posicao);
                if (c >= '0' && c <= '9') { posicao++; continue; }
                if (c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-') { decimal = true; posicao++; continue; }
                break;
            }
            String parte = entrada.substring(inicio, posicao);
            if (parte.isEmpty() || parte.equals("-")) throw new IllegalArgumentException("JSON invalido");
            try {
                return decimal ? (Object) Double.valueOf(parte) : (Object) Long.valueOf(parte);
            } catch (NumberFormatException e) { throw new IllegalArgumentException("Numero invalido"); }
        }
    }
}
