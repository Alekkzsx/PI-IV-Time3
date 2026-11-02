// Desenvolvido por Marcelo Zarpelon

package utils;

import java.util.List;
import java.util.Map;

// Teste sem bibliotecas: compilar junto com src e executar com java.
public class JsonTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static boolean rejeita(String json) {
        try { Json.analisar(json); return false; } catch (IllegalArgumentException e) { return true; }
    }

    public static void main(String[] args) {
        Map<String, Object> o = Json.analisarObjeto("{\"nome\":\"Ana\",\"idade\":30,\"nota\":8.5,\"ativo\":true,\"x\":null,\"aulas\":[1,2,{\"a\":\"b\"}]}");
        esperar(o.get("nome").equals("Ana"), "texto");
        esperar(o.get("idade").equals(30L), "inteiro vira Long");
        esperar(o.get("nota").equals(8.5), "decimal vira Double");
        esperar(o.get("ativo").equals(Boolean.TRUE), "booleano");
        esperar(o.containsKey("x") && o.get("x") == null, "nulo");
        esperar(((List<?>) o.get("aulas")).size() == 3, "lista");
        esperar(Json.escrever(Json.analisar(Json.escrever(o))).equals(Json.escrever(o)), "ida e volta");
        esperar(Json.analisarObjeto("{\"t\":\"a\\n\\u00e9\\\"\"}").get("t").equals("a\né\""), "escapes");
        esperar(rejeita("{\"a\":1,}"), "rejeita virgula final");
        esperar(rejeita("{\"a\":1,\"a\":2}"), "rejeita campo repetido");
        esperar(rejeita("{\"a\":1} x"), "rejeita conteudo extra");
        esperar(rejeita("[1,2"), "rejeita lista incompleta");
        esperar(rejeita("[".repeat(100)), "rejeita aninhamento excessivo");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
