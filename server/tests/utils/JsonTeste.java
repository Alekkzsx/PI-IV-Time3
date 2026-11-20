// Desenvolvido por Murillo Caravita - RA: 25014012

package utils;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Teste sem bibliotecas para Json e JsonSimples.
/**
 * Suite dos parsers JSON: mapeamento de tipos (Long/Double/Boolean/null/lista),
 * round-trip escrever->analisar, escapes RFC e rejeicoes de seguranca (virgula final,
 * campo repetido, conteudo extra, entrada truncada, aninhamento excessivo).
 */
public class JsonTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /** @return true se o parser REJEITOU a entrada (o comportamento esperado nos cenarios negativos). */
    static boolean rejeita(String json) {
        try {
            Json.analisar(json);
            return false;
        } catch (IllegalArgumentException e) {
            return true;
        }
    }

    /** Repete um fragmento N vezes (monta o payload de aninhamento profundo do cenario anti-DoS). */
    private static String repetir(String base, int vezes) {
        StringBuilder sb = new StringBuilder(base.length() * vezes);
        for (int i = 0; i < vezes; i++) sb.append(base);
        return sb.toString();
    }

    /** Executa os cenarios da suite; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;
        Map<String, Object> o = Json.analisarObjeto("{\"nome\":\"Ana\",\"idade\":30,\"nota\":8.5,\"ativo\":true,\"x\":null,\"aulas\":[1,2,{\"a\":\"b\"}]}");
        esperar(o.get("nome").equals("Ana"), "Json: texto");
        esperar(o.get("idade").equals(Long.valueOf(30L)), "Json: inteiro vira Long");
        esperar(o.get("nota").equals(Double.valueOf(8.5)), "Json: decimal vira Double");
        esperar(o.get("ativo").equals(Boolean.TRUE), "Json: booleano");
        esperar(o.containsKey("x") && o.get("x") == null, "Json: nulo");
        esperar(((List<?>) o.get("aulas")).size() == 3, "Json: lista");
        esperar(Json.escrever(Json.analisar(Json.escrever(o))).equals(Json.escrever(o)), "Json: ida e volta");
        esperar(Json.analisarObjeto("{\"t\":\"a\\n\\u00e9\\\"\"}").get("t").equals("a\né\""), "Json: escapes");
        esperar(rejeita("{\"a\":1,}"), "Json: rejeita virgula final");
        esperar(rejeita("{\"a\":1,\"a\":2}"), "Json: rejeita campo repetido");
        esperar(rejeita("{\"a\":1} x"), "Json: rejeita conteudo extra");
        esperar(rejeita("[1,2"), "Json: rejeita lista incompleta");
        esperar(rejeita(repetir("[", 100)), "Json: rejeita aninhamento excessivo");

        Map<String, String> simples = new LinkedHashMap<String, String>();
        simples.put("identity", "24802449");
        simples.put("profile", "aluno");
        String serializado = JsonSimples.objeto(simples);
        Map<String, String> lido = JsonSimples.analisar(serializado);
        esperar("24802449".equals(lido.get("identity")) && "aluno".equals(lido.get("profile")), "JsonSimples: objeto e analisar");

        return falhas;
    }

    /** Runner isolado: exit 1 se houver falha. */
    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes passaram");
    }
}

