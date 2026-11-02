// Desenvolvido por Marcelo Zarpelon

package docente;

import database.BancoMemoria;
import database.Colecao;
import server.RequisicaoHttp;
import server.RespostaHttp;
import utils.Json;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

// Teste sem bibliotecas das acoes do docente com regra de negocio.
public class AcoesDocenteTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static String chamar(AcoesDocenteHandler h, String metodo, String caminho, String corpo) throws IOException {
        byte[] b = corpo.getBytes(StandardCharsets.UTF_8);
        String pedido = metodo + " " + caminho + " HTTP/1.1\r\nHost: x\r\nContent-Length: " + b.length + "\r\n\r\n" + corpo;
        RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(pedido.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        h.handle(req, new RespostaHttp(saida));
        return saida.toString(StandardCharsets.UTF_8);
    }

    static boolean status(String r, int codigo) { return r.startsWith("HTTP/1.1 " + codigo + " "); }

    static void guardar(Colecao c, String json) { c.inserir(Json.analisarObjeto(json)); }

    static String acao(AcoesDocenteHandler h, String nome, String corpo) throws IOException {
        return chamar(h, "POST", AcoesDocenteHandler.RAIZ + "/" + nome, corpo);
    }

    public static void main(String[] args) throws IOException {
        BancoMemoria banco = new BancoMemoria();
        guardar(banco.colecao(DocenteEsquemas.DOCENTES), "{\"id\":\"p1\",\"twoFactorEnabled\":true,\"activeSessions\":[{\"id\":\"s1\"},{\"id\":\"s2\"}]}");
        guardar(banco.colecao(DocenteEsquemas.CURSOS), "{\"id\":\"c1\",\"syllabusUnits\":[{\"id\":\"u1\",\"completedClasses\":8,\"totalClasses\":10},{\"id\":\"u2\",\"completedClasses\":10,\"totalClasses\":10},{\"id\":\"u3\",\"completedClasses\":0,\"totalClasses\":12}],\"materials\":[{\"id\":\"m0\",\"title\":\"antigo\"}]}");
        guardar(banco.colecao(DocenteEsquemas.AULAS), "{\"id\":\"a1\",\"isHomologated\":true,\"attendanceList\":[{\"studentId\":\"st1\",\"status\":\"presente\",\"accumulatedAbsences\":2},{\"studentId\":\"st2\",\"status\":\"ausente\",\"accumulatedAbsences\":9}]}");
        guardar(banco.colecao(DocenteEsquemas.TAREFAS), "{\"id\":\"t1\",\"rubricCriteria\":[{\"id\":\"rc1\",\"maxPoints\":4.0},{\"id\":\"rc2\",\"maxPoints\":6.0}],\"submissions\":[{\"id\":\"sub1\",\"status\":\"aguardandoCorrecao\"}]}");
        guardar(banco.colecao(DocenteEsquemas.NOTAS), "{\"id\":\"n1\",\"courseId\":\"c1\",\"studentId\":\"st1\",\"assignmentsScore\":9.0,\"p1Score\":8.5,\"projectsScore\":8.8,\"p2Score\":9.0,\"attendanceRate\":94.8}");
        AcoesDocenteHandler h = new AcoesDocenteHandler(banco);
        String r;

        // presenca
        r = acao(h, "attendance", "{\"sessionId\":\"a1\",\"studentId\":\"st1\",\"status\":\"ausente\"}");
        esperar(status(r, 200) && r.contains("\"accumulatedAbsences\":3") && r.contains("\"attendanceRate\":92.1") && r.contains("\"riskLevel\":\"regular\""), "falta soma e recalcula frequencia");
        esperar(r.contains("\"isHomologated\":false"), "mudar presenca tira a homologacao");
        r = acao(h, "attendance", "{\"sessionId\":\"a1\",\"studentId\":\"st2\",\"status\":\"presente\"}");
        esperar(r.contains("\"accumulatedAbsences\":8") && r.contains("\"riskLevel\":\"atencao\""), "voltar a presente desconta falta e mantem risco de atencao");
        for (int i = 0; i < 4; i++) acao(h, "attendance", "{\"sessionId\":\"a1\",\"studentId\":\"st2\",\"status\":\"" + (i % 2 == 0 ? "ausente" : "presente") + "\"}");
        esperar(status(acao(h, "attendance", "{\"sessionId\":\"a1\",\"studentId\":\"st9\",\"status\":\"presente\"}"), 404), "aluno fora da lista da 404");
        esperar(status(acao(h, "attendance", "{\"sessionId\":\"zz\",\"studentId\":\"st1\",\"status\":\"presente\"}"), 404), "aula inexistente da 404");
        esperar(status(acao(h, "attendance", "{\"sessionId\":\"a1\",\"studentId\":\"st1\",\"status\":\"faltou\"}"), 400), "status invalido da 400");

        // homologacao
        r = acao(h, "homologate", "{\"sessionId\":\"a1\"}");
        esperar(status(r, 200) && r.contains("\"isHomologated\":true"), "homologar a aula");

        // rubrica
        r = acao(h, "rubric-evaluation", "{\"assignmentId\":\"t1\",\"submissionId\":\"sub1\",\"feedback\":\"bom\",\"scores\":{\"rc1\":4,\"rc2\":3}}");
        esperar(status(r, 200) && r.contains("\"grade\":7.0") && r.contains("\"status\":\"corrigido\"") && r.contains("\"teacherFeedback\":\"bom\""), "corrige entrega e calcula nota");
        esperar(!banco.colecao(DocenteEsquemas.TAREFAS).buscar("t1").get("rubricCriteria").toString().contains("assignedScore"), "criterios da tarefa nao guardam nota");
        esperar(status(acao(h, "rubric-evaluation", "{\"assignmentId\":\"t1\",\"submissionId\":\"sub1\",\"scores\":{\"rc1\":5}}"), 400), "nota acima do maximo do criterio da 400");
        esperar(status(acao(h, "rubric-evaluation", "{\"assignmentId\":\"t1\",\"submissionId\":\"zz\",\"scores\":{}}"), 404), "entrega inexistente da 404");

        // ementa
        r = acao(h, "syllabus-advance", "{\"courseId\":\"c1\",\"unitId\":\"u1\"}");
        esperar(r.contains("\"completedClasses\":10"), "avanca 2 aulas");
        r = acao(h, "syllabus-advance", "{\"courseId\":\"c1\",\"unitId\":\"u1\"}");
        esperar(r.contains("\"completedClasses\":8"), "unidade completa volta 2 aulas");
        r = acao(h, "syllabus-advance", "{\"courseId\":\"c1\",\"unitId\":\"u3\"}");
        esperar(r.contains("\"completedClasses\":2"), "avanca a partir de zero");

        // material
        r = acao(h, "publish-material", "{\"courseId\":\"c1\",\"title\":\"Slides\",\"type\":\"PPT\"}");
        esperar(status(r, 201) && r.contains("\"title\":\"Slides\"") && r.contains("\"type\":\"PPT\""), "publica material");
        esperar(((java.util.List<?>) banco.colecao(DocenteEsquemas.CURSOS).buscar("c1").get("materials")).size() == 2, "material entra na lista do curso");
        esperar(status(acao(h, "publish-material", "{\"courseId\":\"c1\",\"title\":\"  \"}"), 400), "titulo em branco da 400");

        // notas
        r = acao(h, "grade", "{\"courseId\":\"c1\",\"studentId\":\"st1\",\"p1Score\":10}");
        esperar(status(r, 200) && r.contains("\"p1Score\":10.0") && r.contains("\"finalAverage\":") && r.contains("\"status\":\"aprovado\""), "lanca nota e recalcula");
        esperar(status(acao(h, "grade", "{\"courseId\":\"c1\",\"studentId\":\"st1\",\"p1Score\":11}"), 400), "nota acima de 10 da 400");
        esperar(status(acao(h, "grade", "{\"courseId\":\"c1\",\"studentId\":\"st9\",\"p1Score\":5}"), 404), "aluno sem registro da 404");
        esperar(((Number) banco.colecao(DocenteEsquemas.NOTAS).buscar("n1").get("p1Score")).doubleValue() == 10.0, "nota fica gravada");

        // perfil
        r = acao(h, "toggle-two-factor", "{\"profileId\":\"p1\"}");
        esperar(r.contains("\"twoFactorEnabled\":false"), "alterna dois fatores");
        r = acao(h, "disconnect-session", "{\"profileId\":\"p1\",\"sessionId\":\"s1\"}");
        esperar(status(r, 200) && !r.contains("\"s1\"") && r.contains("\"s2\""), "encerra a sessao escolhida");
        esperar(status(acao(h, "disconnect-session", "{\"profileId\":\"p1\",\"sessionId\":\"s1\"}"), 404), "sessao ja encerrada da 404");

        // geral
        esperar(status(acao(h, "inexistente", "{}"), 404), "acao desconhecida da 404");
        esperar(status(chamar(h, "GET", AcoesDocenteHandler.RAIZ + "/attendance", ""), 405), "GET nao permitido");
        esperar(status(chamar(h, "OPTIONS", AcoesDocenteHandler.RAIZ + "/attendance", ""), 204), "OPTIONS responde 204");
        esperar(status(acao(h, "attendance", "nao e json"), 400), "json invalido da 400");
        esperar(status(acao(h, "attendance", "{\"sessionId\":\"../x\",\"studentId\":\"st1\",\"status\":\"presente\"}"), 400), "id com caracteres invalidos da 400");

        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
