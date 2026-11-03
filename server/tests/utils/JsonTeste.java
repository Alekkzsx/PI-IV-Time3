// Desenvolvido por Marcelo Zarpelon e Guilherme Henrique Moreira

package utils;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Teste sem bibliotecas para Json e JsonSimples.
public class JsonTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static boolean rejeita(String json) {
        try {
            Json.analisar(json);
            return false;
        } catch (IllegalArgumentException e) {
            return true;
        }
    }

    private static String repetir(String base, int vezes) {
        StringBuilder sb = new StringBuilder(base.length() * vezes);
        for (int i = 0; i < vezes; i++) sb.append(base);
        return sb.toString();
    }

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

    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes passaram");
    }
}

