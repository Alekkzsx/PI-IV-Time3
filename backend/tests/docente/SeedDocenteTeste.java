// Desenvolvido por Marcelo Zarpelon

package docente;

import database.BancoMemoria;

import java.util.Map;

// Teste sem bibliotecas: o seed valida contra os esquemas e pode rodar varias vezes sem duplicar.
public class SeedDocenteTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static void main(String[] args) {
        BancoMemoria banco = new BancoMemoria();
        int primeira = SeedDocente.popular(banco);
        int segunda = SeedDocente.popular(banco);
        esperar(primeira == 14 && segunda == 14, "grava 14 documentos nas duas execucoes");
        esperar(banco.colecao(DocenteEsquemas.CURSOS).listar(Map.of()).size() == 3, "3 cursos, sem duplicar na segunda execucao");
        esperar(banco.colecao(DocenteEsquemas.CURSOS).listar(Map.of("teacherIdentity", SeedDocente.DOCENTE)).size() == 3, "cursos ligados ao docente");
        esperar(banco.colecao(DocenteEsquemas.TAREFAS).listar(Map.of("courseId", "course-aps2")).size() == 1, "tarefa ligada ao curso");
        esperar(banco.colecao(DocenteEsquemas.DOCENTES).buscar(SeedDocente.DOCENTE) != null, "perfil do docente existe");
        // Os dados do seed funcionam com as acoes do docente.
        AcoesDocenteHandler acoes = new AcoesDocenteHandler(banco);
        try {
            String r = AcoesDocenteTeste.acao(acoes, "attendance", "{\"sessionId\":\"sess-27\",\"studentId\":\"st-3\",\"status\":\"presente\"}");
            esperar(r.contains("\"accumulatedAbsences\":8"), "acao de presenca funciona sobre a aula do seed");
            r = AcoesDocenteTeste.acao(acoes, "rubric-evaluation", "{\"assignmentId\":\"asg-1\",\"submissionId\":\"sub-1\",\"scores\":{\"rc-1\":4,\"rc-2\":3,\"rc-3\":2}}");
            esperar(r.contains("\"grade\":9.0"), "acao de rubrica funciona sobre a tarefa do seed");
            r = AcoesDocenteTeste.acao(acoes, "syllabus-advance", "{\"courseId\":\"course-aps2\",\"unitId\":\"unit-2\"}");
            esperar(r.contains("\"completedClasses\":10"), "acao de ementa funciona sobre o curso do seed");
            r = AcoesDocenteTeste.acao(acoes, "disconnect-session", "{\"profileId\":\"prof.demo\",\"sessionId\":\"sess-2\"}");
            esperar(r.contains("sess-3") && !r.contains("sess-2"), "acao de sessao funciona sobre o perfil do seed");
        } catch (java.io.IOException e) {
            esperar(false, "acoes sobre o seed: " + e.getMessage());
        }
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
