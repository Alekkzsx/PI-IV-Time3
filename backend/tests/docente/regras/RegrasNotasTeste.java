// Desenvolvido por Marcelo Zarpelon

package docente.regras;

// Teste sem bibliotecas das regras de notas, com valores do gradebook de exemplo do frontend.
public class RegrasNotasTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static boolean rejeita(Runnable acao) {
        try { acao.run(); return false; } catch (IllegalArgumentException e) { return true; }
    }

    public static void main(String[] args) {
        // Gabriel: tarefas 9.0, P1 8.5, projetos 8.8, P2 9.0
        double n1 = RegrasNotas.n1(9.0, 8.5);
        double n2 = RegrasNotas.n2(8.8, 9.0);
        esperar(n1 == 8.7, "N1 = 9.0*0.4 + 8.5*0.6");
        esperar(n2 == 8.9, "N2 = 8.8*0.4 + 9.0*0.6");
        double media = RegrasNotas.mediaFinal(n1, n2);
        esperar(media == 8.8, "media final = N1*0.4 + N2*0.6");
        esperar(RegrasNotas.situacao(media, 94.8).equals("aprovado"), "media 7 ou mais e aprovado");
        esperar(RegrasNotas.situacao(7.0, 80.0).equals("aprovado"), "exatamente 7.0 aprova");
        esperar(RegrasNotas.situacao(6.9, 80.0).equals("exame"), "abaixo de 7 vai para exame");
        esperar(RegrasNotas.situacao(4.0, 80.0).equals("exame"), "exatamente 4.0 ainda e exame");
        esperar(RegrasNotas.situacao(3.9, 80.0).equals("reprovadoPorNota"), "abaixo de 4 reprova por nota");
        esperar(RegrasNotas.situacao(9.5, 74.9).equals("reprovadoPorFalta"), "falta tem prioridade sobre nota");
        esperar(RegrasNotas.situacao(9.5, 75.0).equals("aprovado"), "75% de frequencia e suficiente");
        esperar(rejeita(() -> RegrasNotas.validarNota("p1Score", 10.1)), "rejeita nota acima de 10");
        esperar(rejeita(() -> RegrasNotas.validarNota("p1Score", -0.1)), "rejeita nota negativa");
        esperar(!rejeita(() -> RegrasNotas.validarNota("p1Score", 10.0)), "aceita nota 10");
        esperar(rejeita(() -> RegrasNotas.validarFrequencia(100.1)), "rejeita frequencia acima de 100");
        esperar(rejeita(() -> RegrasNotas.validarNota("p1Score", Double.NaN)), "rejeita NaN");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
