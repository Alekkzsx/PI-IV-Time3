// Desenvolvido por Murillo Caravita - RA: 25014012

package utils;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// JSON completo para objetos, listas, textos, numeros, booleanos e nulo.
/**
 * Parser e serializador JSON completo (RFC 8259) implementado a mao, sem bibliotecas externas.
 *
 * Mapeamento de tipos na leitura: objeto -> LinkedHashMap (preserva ordem), lista -> ArrayList,
 * texto -> String, inteiro -> Long, decimal/expoente -> Double, true/false -> Boolean, null -> null.
 * Endurecimentos: limite de profundidade (anti stack overflow/DoS), rejeicao de campos repetidos
 * (anti JSON smuggling) e de caracteres de controle crus dentro de strings.
 *
 * Para payloads planos so de texto existe o irmao mais leve {@link JsonSimples}.
 */
public final class Json {
    // Limite de aninhamento: payloads maliciosos com centenas de niveis estourariam a pilha da recursao.
    private static final int PROFUNDIDADE_MAXIMA = 32;

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private Json() {}

    /**
     * Analisa qualquer valor JSON valido (objeto, lista, escalar) via parser descendente recursivo.
     *
     * @param json texto JSON completo
     * @return valor Java equivalente (Map, List, String, Long, Double, Boolean ou null)
     * @throws IllegalArgumentException se o JSON for invalido, profundo demais ou tiver conteudo extra apos o valor
     */
    public static Object analisar(String json) {
        if (json == null) throw new IllegalArgumentException("JSON vazio");
        Leitor leitor = new Leitor(json);
        Object valor = leitor.valor(0);
        leitor.espacos();
        // Exige consumo total da entrada: "{} lixo" nao pode passar como valido.
        if (leitor.posicao != json.length()) throw new IllegalArgumentException("JSON com conteudo extra");
        return valor;
    }

    /**
     * Atalho tipado para corpos de requisicao: exige que a raiz do JSON seja um objeto.
     *
     * @throws IllegalArgumentException se a raiz for lista/escalar ou o JSON for invalido
     */
    @SuppressWarnings("unchecked")
    public static Map<String, Object> analisarObjeto(String json) {
        Object valor = analisar(json);
        if (!(valor instanceof Map)) throw new IllegalArgumentException("JSON deve ser um objeto");
        return (Map<String, Object>) valor;
    }

    /**
     * Serializa uma arvore Java (Map/Iterable/escalar) para texto JSON.
     * Date e Instant viram string ISO-8601; tipos desconhecidos geram erro em vez de saida corrompida.
     */
    public static String escrever(Object valor) {
        StringBuilder texto = new StringBuilder();
        escrever(valor, texto);
        return texto.toString();
    }

    /** Despacho recursivo por tipo em runtime; o StringBuilder acumula a saida sem copias intermediarias. */
    private static void escrever(Object valor, StringBuilder texto) {
        if (valor == null) { texto.append("null"); return; }
        if (valor instanceof String) { texto.append(JsonSimples.escapar((String) valor)); return; }
        if (valor instanceof Date) {
            texto.append(JsonSimples.escapar(Instant.ofEpochMilli(((Date) valor).getTime()).toString()));
            return;
        }
        if (valor instanceof Instant) {
            texto.append(JsonSimples.escapar(valor.toString()));
            return;
        }
        if (valor instanceof Boolean || valor instanceof Integer || valor instanceof Long) { texto.append(valor); return; }
        if (valor instanceof Double || valor instanceof Float) {
            double numero = ((Number) valor).doubleValue();
            // RFC 8259 nao admite NaN/Infinity: falhar aqui evita emitir JSON que o cliente nao consegue parsear.
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

    /**
     * Cursor de leitura do parser descendente recursivo: cada metodo consome exatamente
     * um nao terminal da gramatica JSON e deixa 'posicao' apontando para o proximo token.
     */
    private static final class Leitor {
        private final String entrada;
        private int posicao;

        Leitor(String entrada) { this.entrada = entrada; }

        /** Avanca o cursor sobre espacos em branco entre tokens. */
        void espacos() {
            while (posicao < entrada.length() && Character.isWhitespace(entrada.charAt(posicao))) posicao++;
        }

        /** Espia o proximo caractere nao espaco sem consumi-lo; falha se a entrada acabou. */
        char proximo() {
            espacos();
            if (posicao >= entrada.length()) throw new IllegalArgumentException("JSON incompleto");
            return entrada.charAt(posicao);
        }

        /** Consome o caractere estrutural esperado ('{', ':', '"'...) ou rejeita o JSON. */
        void exigir(char esperado) {
            if (proximo() != esperado) throw new IllegalArgumentException("JSON invalido: esperado " + esperado);
            posicao++;
        }

        /** Regra principal da gramatica: decide o tipo do valor pelo primeiro caractere e delega. */
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

        /** Consome um literal fixo (true/false/null) conferindo o texto exato. */
        void literal(String esperado) {
            if (!entrada.startsWith(esperado, posicao)) throw new IllegalArgumentException("JSON invalido");
            posicao += esperado.length();
        }

        /** Le um objeto JSON; LinkedHashMap preserva a ordem dos campos do payload original. */
        Map<String, Object> objeto(int nivel) {
            Map<String, Object> campos = new LinkedHashMap<String, Object>();
            exigir('{');
            if (proximo() == '}') { posicao++; return campos; }
            while (true) {
                String chave = texto();
                exigir(':');
                // Chave duplicada e rejeitada: parsers diferentes escolheriam valores diferentes (JSON smuggling).
                if (campos.containsKey(chave)) throw new IllegalArgumentException("Campo repetido: " + chave);
                campos.put(chave, valor(nivel + 1));
                char c = proximo();
                posicao++;
                if (c == '}') return campos;
                if (c != ',') throw new IllegalArgumentException("JSON invalido: esperado , ou }");
            }
        }

        /** Le uma lista JSON consumindo valores separados por virgula ate o ']' de fechamento. */
        List<Object> lista(int nivel) {
            List<Object> itens = new ArrayList<Object>();
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

        /**
         * Le uma string JSON com aspas, processando escapes (\", \\, \n, \\uXXXX...).
         * Caracteres de controle crus (< 32) sao proibidos pela RFC dentro de strings.
         */
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
                            // Escape \\uXXXX: consome exatamente 4 digitos hexadecimais e converte para o char UTF-16.
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

        /**
         * Le um numero JSON varrendo sinal/digitos/ponto/expoente.
         * Heuristica de tipo: sem ponto nem expoente devolve Long (preserva precisao de ids/timestamps);
         * caso contrario Double.
         */
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