// Desenvolvido por Marcelo Zarpelon

package docente.regras;

// Teste sem bibliotecas das regras de frequencia.
public class RegrasPresencaTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static void main(String[] args) {
        esperar(RegrasPresenca.novasFaltas(2, "presente", "ausente") == 3, "presente para ausente soma uma falta");
        esperar(RegrasPresenca.novasFaltas(3, "ausente", "presente") == 2, "ausente para presente desconta");
        esperar(RegrasPresenca.novasFaltas(3, "ausente", "justificada") == 2, "ausente para justificada desconta");
        esperar(RegrasPresenca.novasFaltas(3, "presente", "justificada") == 3, "presente para justificada nao muda");
        esperar(RegrasPresenca.novasFaltas(3, "ausente", "ausente") == 3, "ausente repetido nao muda");
        esperar(RegrasPresenca.novasFaltas(0, "ausente", "presente") == 0, "nunca abaixo de zero");
        esperar(RegrasPresenca.novasFaltas(40, "presente", "ausente") == 40, "limitado a 40 faltas");
        esperar(RegrasPresenca.taxa(2, 38) == 94.7, "taxa com 2 faltas em 38 aulas");
        esperar(RegrasPresenca.taxa(9, 38) == 76.3, "taxa com 9 faltas em 38 aulas");
        esperar(RegrasPresenca.taxa(0, 38) == 100.0, "taxa sem faltas");
        esperar(RegrasPresenca.risco(80.0).equals("regular"), "80% e regular");
        esperar(RegrasPresenca.risco(79.9).equals("atencao"), "abaixo de 80% e atencao");
        esperar(RegrasPresenca.risco(75.0).equals("atencao"), "75% ainda e atencao");
        esperar(RegrasPresenca.risco(74.9).equals("critico"), "abaixo de 75% e critico");
        boolean rejeitou = false;
        try { RegrasPresenca.taxa(1, 0); } catch (IllegalArgumentException e) { rejeitou = true; }
        esperar(rejeitou, "rejeita zero aulas");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
