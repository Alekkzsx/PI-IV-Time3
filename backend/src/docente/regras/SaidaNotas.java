// Desenvolvido por Marcelo Zarpelon

package docente.regras;

import java.util.Map;

// Acrescenta ao documento de nota os campos calculados que o frontend espera em StudentGrade:
// n1Total, n2Total, finalAverage e status.
public final class SaidaNotas {
    private SaidaNotas() {}

    private static double numero(Map<String, Object> documento, String campo) {
        Object valor = documento.get(campo);
        return valor instanceof Number ? ((Number) valor).doubleValue() : 0.0;
    }

    public static Map<String, Object> calcular(Map<String, Object> documento) {
        double n1 = RegrasNotas.n1(numero(documento, "assignmentsScore"), numero(documento, "p1Score"));
        double n2 = RegrasNotas.n2(numero(documento, "projectsScore"), numero(documento, "p2Score"));
        double media = RegrasNotas.mediaFinal(n1, n2);
        documento.put("n1Total", n1);
        documento.put("n2Total", n2);
        documento.put("finalAverage", media);
        documento.put("status", RegrasNotas.situacao(media, numero(documento, "attendanceRate")));
        return documento;
    }
}
