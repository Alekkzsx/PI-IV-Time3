// Desenvolvido por Marcelo Zarpelon

package docente.regras;

// Calculo das medias e da situacao academica, igual a StudentGrade no frontend:
// N1 = tarefas*0.4 + P1*0.6, N2 = projetos*0.4 + P2*0.6, media final = N1*0.4 + N2*0.6.
public final class RegrasNotas {
    public static final double MEDIA_APROVACAO = 7.0;
    public static final double MEDIA_EXAME = 4.0;
    public static final double FREQUENCIA_MINIMA = 75.0;

    private RegrasNotas() {}

    // Uma casa decimal, como toStringAsFixed(1) do Dart.
    static double arredondar(double valor) { return Math.round(valor * 10.0) / 10.0; }

    public static double n1(double tarefas, double p1) { return arredondar(tarefas * 0.4 + p1 * 0.6); }

    public static double n2(double projetos, double p2) { return arredondar(projetos * 0.4 + p2 * 0.6); }

    public static double mediaFinal(double n1, double n2) { return arredondar(n1 * 0.4 + n2 * 0.6); }

    // aprovado, exame, reprovadoPorNota ou reprovadoPorFalta (a falta tem prioridade).
    public static String situacao(double mediaFinal, double frequencia) {
        if (frequencia < FREQUENCIA_MINIMA) return "reprovadoPorFalta";
        if (mediaFinal >= MEDIA_APROVACAO) return "aprovado";
        if (mediaFinal >= MEDIA_EXAME) return "exame";
        return "reprovadoPorNota";
    }

    // Notas vao de 0 a 10.
    public static double validarNota(String campo, double nota) {
        if (Double.isNaN(nota) || nota < 0.0 || nota > 10.0) throw new IllegalArgumentException("Nota fora do intervalo de 0 a 10: " + campo);
        return nota;
    }

    // Frequencia vai de 0 a 100.
    public static double validarFrequencia(double frequencia) {
        if (Double.isNaN(frequencia) || frequencia < 0.0 || frequencia > 100.0) throw new IllegalArgumentException("Frequencia fora do intervalo de 0 a 100");
        return frequencia;
    }
}
