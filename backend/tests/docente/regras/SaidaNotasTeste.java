// Desenvolvido por Marcelo Zarpelon

package docente.regras;

import java.util.LinkedHashMap;
import java.util.Map;

// Teste sem bibliotecas dos campos calculados da nota.
public class SaidaNotasTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static void main(String[] args) {
        Map<String, Object> d = new LinkedHashMap<>();
        d.put("assignmentsScore", 9.0);
        d.put("p1Score", 8.5);
        d.put("projectsScore", 8.8);
        d.put("p2Score", 9.0);
        d.put("attendanceRate", 94.8);
        SaidaNotas.calcular(d);
        esperar(d.get("n1Total").equals(8.7) && d.get("n2Total").equals(8.9), "calcula N1 e N2");
        esperar(d.get("finalAverage").equals(8.8) && d.get("status").equals("aprovado"), "media final e status aprovado");

        Map<String, Object> vazio = new LinkedHashMap<>();
        SaidaNotas.calcular(vazio);
        esperar(vazio.get("finalAverage").equals(0.0) && vazio.get("status").equals("reprovadoPorFalta"), "sem notas nem frequencia reprova por falta");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
