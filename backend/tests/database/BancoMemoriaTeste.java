// Desenvolvido por Marcelo Zarpelon

package database;

import java.util.LinkedHashMap;
import java.util.Map;

// Teste sem bibliotecas do banco em memoria.
public class BancoMemoriaTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static Map<String, Object> doc(String id, String curso) {
        Map<String, Object> d = new LinkedHashMap<>();
        d.put("id", id);
        d.put("cursoId", curso);
        return d;
    }

    public static void main(String[] args) {
        Colecao c = new BancoMemoria().colecao("tarefas");
        c.inserir(doc("t1", "c1"));
        c.inserir(doc("t2", "c2"));
        esperar(c.listar(Map.of()).size() == 2, "lista tudo com filtro vazio");
        esperar(c.listar(Map.of("cursoId", "c1")).size() == 1, "filtra por campo");
        esperar(c.buscar("t1") != null && c.buscar("zz") == null, "busca por id");
        boolean duplicou = false;
        try { c.inserir(doc("t1", "c9")); } catch (IdDuplicadoException e) { duplicou = true; }
        esperar(duplicou, "rejeita id duplicado");
        esperar(c.substituir("t1", doc("t1", "c3")) && c.buscar("t1").get("cursoId").equals("c3"), "substitui");
        esperar(!c.substituir("zz", doc("zz", "c")), "substituir inexistente retorna false");
        Map<String, Object> copia = c.buscar("t2");
        copia.put("cursoId", "alterado");
        esperar(c.buscar("t2").get("cursoId").equals("c2"), "buscar devolve copia");
        esperar(c.remover("t2") && !c.remover("t2"), "remove uma vez");
        esperar(new BancoMemoria().colecao("a") != new BancoMemoria().colecao("a"), "bancos independentes");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
