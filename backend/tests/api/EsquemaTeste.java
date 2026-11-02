// Desenvolvido por Marcelo Zarpelon

package api;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Teste sem bibliotecas da validacao de esquema.
public class EsquemaTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static boolean rejeita(Esquema e, Map<String, Object> doc, boolean parcial) {
        try { e.validar(doc, parcial); return false; } catch (IllegalArgumentException ex) { return true; }
    }

    static Map<String, Object> mapa(Object... pares) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < pares.length; i += 2) m.put((String) pares[i], pares[i + 1]);
        return m;
    }

    public static void main(String[] args) {
        Esquema e = new Esquema(Campo.texto("titulo", true, 10), Campo.decimal("peso", true),
                Campo.inteiro("horas", false), Campo.booleano("urgente", false), Campo.lista("itens", false, 2));

        Map<String, Object> ok = e.validar(mapa("titulo", "  P1 ", "peso", 1L, "horas", 4L, "urgente", true, "itens", List.of("a")), false);
        esperar(ok.get("titulo").equals("P1"), "texto e aparado");
        esperar(ok.get("peso").equals(1.0), "inteiro aceito como decimal vira Double");
        esperar(rejeita(e, mapa("titulo", "x"), false), "obrigatorio ausente");
        esperar(!rejeita(e, mapa("titulo", "x"), true), "parcial tolera ausente");
        esperar(rejeita(e, mapa("titulo", "x", "peso", 1L, "extra", "y"), false), "campo desconhecido");
        esperar(rejeita(e, mapa("titulo", "x", "peso", 1L, "id", "a"), false), "id nao aceito no corpo");
        esperar(rejeita(e, mapa("titulo", "texto muito longo", "peso", 1L), false), "texto acima do limite");
        esperar(rejeita(e, mapa("titulo", "   ", "peso", 1L), false), "texto obrigatorio em branco");
        esperar(rejeita(e, mapa("titulo", "x", "peso", "1"), false), "decimal exige numero");
        esperar(rejeita(e, mapa("titulo", "x", "peso", 1L, "horas", 1.5), false), "inteiro rejeita decimal");
        esperar(rejeita(e, mapa("titulo", "x", "peso", 1L, "urgente", "sim"), false), "booleano exige booleano");
        esperar(rejeita(e, mapa("titulo", "x", "peso", 1L, "itens", List.of(1, 2, 3)), false), "lista acima do limite");
        esperar(rejeita(e, mapa("titulo", null, "peso", 1L), false), "nulo rejeitado");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
