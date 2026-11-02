// Desenvolvido por Marcelo Zarpelon

package docente.regras;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Teste sem bibliotecas da correcao por rubrica.
public class RegrasRubricaTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static Map<String, Object> criterio(String id, double maximo) {
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("id", id);
        c.put("title", "Criterio " + id);
        c.put("maxPoints", maximo);
        return c;
    }

    static List<Map<String, Object>> criterios() {
        List<Map<String, Object>> l = new ArrayList<>();
        l.add(criterio("rc-1", 4.0));
        l.add(criterio("rc-2", 3.0));
        l.add(criterio("rc-3", 3.0));
        return l;
    }

    static boolean rejeita(Runnable acao) {
        try { acao.run(); return false; } catch (IllegalArgumentException e) { return true; }
    }

    public static void main(String[] args) {
        List<Map<String, Object>> c = RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-1", 4.0, "rc-2", 2.0, "rc-3", 3.0));
        esperar(c.get(1).get("assignedScore").equals(2.0), "preenche assignedScore");
        esperar(RegrasRubrica.notaFinal(c) == 9.0, "9 de 10 pontos vira nota 9.0");
        c = RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-1", 2.0));
        esperar(RegrasRubrica.notaFinal(c) == 2.0, "criterio sem nota conta como zero");
        c = RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-1", 3.0, "rc-2", 2.0, "rc-3", 2.0));
        esperar(RegrasRubrica.notaFinal(c) == 7.0, "7 de 10 pontos vira nota 7.0");
        esperar(rejeita(() -> RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-1", 4.1))), "rejeita nota acima do maximo do criterio");
        esperar(rejeita(() -> RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-1", -1.0))), "rejeita nota negativa");
        esperar(rejeita(() -> RegrasRubrica.aplicarNotas(criterios(), Map.of("rc-9", 1.0))), "rejeita criterio que nao existe");
        esperar(rejeita(() -> RegrasRubrica.notaFinal(new ArrayList<>())), "rejeita tarefa sem criterios");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
