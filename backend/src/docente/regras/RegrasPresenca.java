// Desenvolvido por Marcelo Zarpelon

package docente.regras;

// Regras de frequencia do diario de classe, as mesmas aplicadas hoje no frontend (DocenteController.toggleAttendance).
public final class RegrasPresenca {
    public static final int AULAS_PADRAO = 38;
    public static final int MAXIMO_FALTAS = 40;
    public static final double LIMITE_CRITICO = 75.0;
    public static final double LIMITE_ATENCAO = 80.0;

    private RegrasPresenca() {}

    // Faltas acumuladas apos trocar o status: so "ausente" conta como falta; limitado entre 0 e MAXIMO_FALTAS.
    public static int novasFaltas(int faltasAtuais, String statusAnterior, String statusNovo) {
        boolean eraAusente = "ausente".equals(statusAnterior);
        boolean seraAusente = "ausente".equals(statusNovo);
        int delta = 0;
        if (!eraAusente && seraAusente) delta = 1;
        if (eraAusente && !seraAusente) delta = -1;
        return Math.max(0, Math.min(MAXIMO_FALTAS, faltasAtuais + delta));
    }

    // Percentual de presenca com uma casa decimal.
    public static double taxa(int faltas, int aulasDadas) {
        if (aulasDadas <= 0) throw new IllegalArgumentException("Numero de aulas deve ser positivo");
        return Math.round(((aulasDadas - faltas) / (double) aulasDadas) * 1000.0) / 10.0;
    }

    // regular, atencao (abaixo de 80%) ou critico (abaixo de 75%).
    public static String risco(double taxa) {
        if (taxa < LIMITE_CRITICO) return "critico";
        if (taxa < LIMITE_ATENCAO) return "atencao";
        return "regular";
    }
}
