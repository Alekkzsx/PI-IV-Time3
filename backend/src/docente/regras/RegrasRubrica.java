// Desenvolvido por Marcelo Zarpelon

package docente.regras;

import java.util.List;
import java.util.Map;

// Correcao de entrega por rubrica, igual a RubricEvaluationModal no frontend:
// nota = soma das notas dos criterios / soma dos maximos * 10, com uma casa decimal.
public final class RegrasRubrica {
    private RegrasRubrica() {}

    // Aplica as notas informadas (criterionId -> nota) aos criterios da tarefa.
    // Retorna os criterios com assignedScore preenchido; criterio sem nota informada recebe 0.
    public static List<Map<String, Object>> aplicarNotas(List<Map<String, Object>> criterios, Map<String, Double> notas) {
        for (String id : notas.keySet()) {
            boolean existe = false;
            for (Map<String, Object> criterio : criterios) if (id.equals(criterio.get("id"))) existe = true;
            if (!existe) throw new IllegalArgumentException("Criterio inexistente na tarefa: " + id);
        }
        for (Map<String, Object> criterio : criterios) {
            Double nota = notas.getOrDefault((String) criterio.get("id"), 0.0);
            double maximo = numero(criterio.get("maxPoints"));
            if (nota < 0.0 || nota > maximo) throw new IllegalArgumentException("Nota do criterio fora do intervalo de 0 a " + maximo + ": " + criterio.get("id"));
            criterio.put("assignedScore", nota);
        }
        return criterios;
    }

    // Nota final de 0 a 10 a partir dos criterios ja avaliados.
    public static double notaFinal(List<Map<String, Object>> criterios) {
        double total = 0.0;
        double maximo = 0.0;
        for (Map<String, Object> criterio : criterios) {
            total += numero(criterio.get("assignedScore"));
            maximo += numero(criterio.get("maxPoints"));
        }
        if (maximo <= 0.0) throw new IllegalArgumentException("A tarefa nao tem criterios com pontuacao");
        return Math.round(total / maximo * 100.0) / 10.0;
    }

    private static double numero(Object valor) {
        if (valor instanceof Number) return ((Number) valor).doubleValue();
        return 0.0;
    }
}
