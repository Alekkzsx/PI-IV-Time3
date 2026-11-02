// Desenvolvido por Marcelo Zarpelon

package docente;

import database.BancoDados;
import database.Colecao;
import docente.regras.RegrasNotas;
import docente.regras.RegrasPresenca;
import docente.regras.RegrasRubrica;
import docente.regras.SaidaNotas;
import server.HttpUtils;
import server.ManipuladorHttp;
import server.RequisicaoHttp;
import server.RespostaHttp;
import utils.Json;
import utils.JsonSimples;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Acoes do docente que tem regra de negocio, em POST /api/docente/actions/{acao}.
// Cada acao le o documento, aplica a regra no servidor e grava; o cliente nao envia valores calculados.
public class AcoesDocenteHandler implements ManipuladorHttp {
    public static final String RAIZ = "/api/docente/actions";

    private final Colecao perfis;
    private final Colecao planos;
    private final Colecao aulas;
    private final Colecao tarefas;
    private final Colecao notas;

    public AcoesDocenteHandler(BancoDados banco) {
        this.perfis = banco.colecao(DocenteEsquemas.DOCENTES);
        this.planos = banco.colecao(DocenteEsquemas.CURSOS);
        this.aulas = banco.colecao(DocenteEsquemas.AULAS);
        this.tarefas = banco.colecao(DocenteEsquemas.TAREFAS);
        this.notas = banco.colecao(DocenteEsquemas.NOTAS);
    }

    private static final class NaoEncontrado extends RuntimeException {
        NaoEncontrado(String mensagem) { super(mensagem); }
    }

    @Override
    public void handle(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        HttpUtils.aplicarHeadersCors(resp);
        if (req.getMetodo().equals("OPTIONS")) { resp.enviar(204, ""); return; }
        String restante = req.getCaminho().substring(RAIZ.length());
        if (!req.getMetodo().equals("POST") || !restante.startsWith("/") || restante.indexOf('/', 1) >= 0) {
            erro(resp, 405, "Use POST em " + RAIZ + "/{acao}");
            return;
        }
        String acao = restante.substring(1);
        try {
            Map<String, Object> corpo = Json.analisarObjeto(req.getCorpo());
            switch (acao) {
                case "attendance": enviar(resp, 200, marcarPresenca(corpo)); return;
                case "homologate": enviar(resp, 200, homologar(corpo)); return;
                case "rubric-evaluation": enviar(resp, 200, corrigirEntrega(corpo)); return;
                case "syllabus-advance": enviar(resp, 200, avancarEmenta(corpo)); return;
                case "publish-material": enviar(resp, 201, publicarMaterial(corpo)); return;
                case "grade": enviar(resp, 200, lancarNota(corpo)); return;
                case "toggle-two-factor": enviar(resp, 200, alternarDoisFatores(corpo)); return;
                case "disconnect-session": enviar(resp, 200, desconectarSessao(corpo)); return;
                default: erro(resp, 404, "Acao desconhecida: " + acao);
            }
        } catch (NaoEncontrado e) {
            erro(resp, 404, e.getMessage());
        } catch (IllegalArgumentException e) {
            erro(resp, 400, e.getMessage());
        }
    }

    // ---- acoes ----

    // Troca o status de presenca de um aluno e recalcula faltas, frequencia e risco; a aula deixa de estar homologada.
    private Map<String, Object> marcarPresenca(Map<String, Object> corpo) {
        String sessaoId = id(corpo, "sessionId");
        String alunoId = id(corpo, "studentId");
        String status = texto(corpo, "status", 20);
        if (!List.of(DocenteEsquemas.STATUS_PRESENCA).contains(status)) {
            throw new IllegalArgumentException("status deve ser presente, ausente ou justificada");
        }
        Map<String, Object> sessao = existente(aulas, sessaoId, "Aula nao encontrada");
        Map<String, Object> aluno = null;
        for (Map<String, Object> item : listaDeMapas(sessao.get("attendanceList"))) {
            if (alunoId.equals(item.get("studentId"))) aluno = item;
        }
        if (aluno == null) throw new NaoEncontrado("Aluno nao esta na lista de presenca desta aula");

        int faltas = RegrasPresenca.novasFaltas(inteiro(aluno.get("accumulatedAbsences")), (String) aluno.get("status"), status);
        double taxa = RegrasPresenca.taxa(faltas, RegrasPresenca.AULAS_PADRAO);
        aluno.put("status", status);
        aluno.put("accumulatedAbsences", (long) faltas);
        aluno.put("attendanceRate", taxa);
        aluno.put("riskLevel", RegrasPresenca.risco(taxa));
        sessao.put("isHomologated", false);
        gravar(aulas, sessaoId, sessao);
        return sessao;
    }

    private Map<String, Object> homologar(Map<String, Object> corpo) {
        String sessaoId = id(corpo, "sessionId");
        Map<String, Object> sessao = existente(aulas, sessaoId, "Aula nao encontrada");
        sessao.put("isHomologated", true);
        gravar(aulas, sessaoId, sessao);
        return sessao;
    }

    // Corrige uma entrega: nota 0 a 10 proporcional aos pontos dos criterios; a entrega passa a "corrigido".
    private Map<String, Object> corrigirEntrega(Map<String, Object> corpo) {
        String tarefaId = id(corpo, "assignmentId");
        String entregaId = id(corpo, "submissionId");
        String feedback = corpo.containsKey("feedback") ? texto(corpo, "feedback", 2000, true) : "";
        Object bruto = corpo.get("scores");
        if (!(bruto instanceof Map)) throw new IllegalArgumentException("scores deve ser um objeto criterio -> nota");
        Map<String, Double> pontuacao = new LinkedHashMap<>();
        for (Map.Entry<?, ?> item : ((Map<?, ?>) bruto).entrySet()) pontuacao.put(String.valueOf(item.getKey()), numero(item.getValue(), "scores"));

        Map<String, Object> tarefa = existente(tarefas, tarefaId, "Tarefa nao encontrada");
        Map<String, Object> entrega = null;
        for (Map<String, Object> item : listaDeMapas(tarefa.get("submissions"))) {
            if (entregaId.equals(item.get("id"))) entrega = item;
        }
        if (entrega == null) throw new NaoEncontrado("Entrega nao encontrada nesta tarefa");

        // Os criterios da tarefa nao guardam nota; a avaliacao fica numa copia dentro da entrega.
        List<Map<String, Object>> avaliados = new ArrayList<>();
        for (Map<String, Object> criterio : listaDeMapas(tarefa.get("rubricCriteria"))) avaliados.add(new LinkedHashMap<>(criterio));
        RegrasRubrica.aplicarNotas(avaliados, pontuacao);
        entrega.put("grade", RegrasRubrica.notaFinal(avaliados));
        entrega.put("status", "corrigido");
        entrega.put("teacherFeedback", feedback);
        entrega.put("rubricEvaluations", avaliados);
        gravar(tarefas, tarefaId, tarefa);
        return entrega;
    }

    // Avanca 2 aulas na unidade (volta 2 se ja estiver completa), sem sair do intervalo 0 ate o total.
    private Map<String, Object> avancarEmenta(Map<String, Object> corpo) {
        String cursoId = id(corpo, "courseId");
        String unidadeId = id(corpo, "unitId");
        Map<String, Object> plano = existente(planos, cursoId, "Curso nao encontrado");
        Map<String, Object> unidade = null;
        for (Map<String, Object> item : listaDeMapas(plano.get("syllabusUnits"))) {
            if (unidadeId.equals(item.get("id"))) unidade = item;
        }
        if (unidade == null) throw new NaoEncontrado("Unidade nao encontrada neste curso");
        int total = inteiro(unidade.get("totalClasses"));
        int feitas = inteiro(unidade.get("completedClasses"));
        int novas = feitas >= total ? feitas - 2 : feitas + 2;
        unidade.put("completedClasses", (long) Math.max(0, Math.min(total, novas)));
        gravar(planos, cursoId, plano);
        return unidade;
    }

    private Map<String, Object> publicarMaterial(Map<String, Object> corpo) {
        String cursoId = id(corpo, "courseId");
        String titulo = texto(corpo, "title", 160);
        Map<String, Object> plano = existente(planos, cursoId, "Curso nao encontrado");
        Map<String, Object> material = new LinkedHashMap<>();
        material.put("id", "mat-" + System.currentTimeMillis());
        material.put("courseId", cursoId);
        material.put("title", titulo);
        material.put("date", LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
        material.put("size", corpo.containsKey("size") ? texto(corpo, "size", 20) : "-");
        material.put("type", corpo.containsKey("type") ? texto(corpo, "type", 20) : "PDF");
        List<Object> materiais = new ArrayList<>();
        materiais.add(material);
        Object existentes = plano.get("materials");
        if (existentes instanceof List) materiais.addAll((List<?>) existentes);
        plano.put("materials", materiais);
        gravar(planos, cursoId, plano);
        return material;
    }

    // Atualiza as notas de um aluno na turma; devolve o registro com medias e situacao recalculadas.
    private Map<String, Object> lancarNota(Map<String, Object> corpo) {
        String cursoId = id(corpo, "courseId");
        String alunoId = id(corpo, "studentId");
        Map<String, String> filtro = new LinkedHashMap<>();
        filtro.put("courseId", cursoId);
        filtro.put("studentId", alunoId);
        List<Map<String, Object>> encontrados = notas.listar(filtro);
        if (encontrados.isEmpty()) throw new NaoEncontrado("Aluno nao encontrado nesta turma");
        Map<String, Object> registro = encontrados.get(0);
        for (String campo : new String[] {"assignmentsScore", "p1Score", "projectsScore", "p2Score"}) {
            if (corpo.containsKey(campo)) registro.put(campo, RegrasNotas.validarNota(campo, numero(corpo.get(campo), campo)));
        }
        gravar(notas, (String) registro.get("id"), registro);
        return SaidaNotas.calcular(new LinkedHashMap<>(registro));
    }

    private Map<String, Object> alternarDoisFatores(Map<String, Object> corpo) {
        String perfilId = id(corpo, "profileId");
        Map<String, Object> perfil = existente(perfis, perfilId, "Perfil nao encontrado");
        boolean ativo = Boolean.TRUE.equals(perfil.get("twoFactorEnabled"));
        perfil.put("twoFactorEnabled", !ativo);
        gravar(perfis, perfilId, perfil);
        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("twoFactorEnabled", !ativo);
        return resposta;
    }

    private Map<String, Object> desconectarSessao(Map<String, Object> corpo) {
        String perfilId = id(corpo, "profileId");
        String sessaoId = id(corpo, "sessionId");
        Map<String, Object> perfil = existente(perfis, perfilId, "Perfil nao encontrado");
        List<Object> restantes = new ArrayList<>();
        boolean removida = false;
        Object atuais = perfil.get("activeSessions");
        if (atuais instanceof List) {
            for (Object item : (List<?>) atuais) {
                if (item instanceof Map && sessaoId.equals(((Map<?, ?>) item).get("id"))) removida = true;
                else restantes.add(item);
            }
        }
        if (!removida) throw new NaoEncontrado("Sessao ativa nao encontrada");
        perfil.put("activeSessions", restantes);
        gravar(perfis, perfilId, perfil);
        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("activeSessions", restantes);
        return resposta;
    }

    // ---- utilitarios ----

    private static String id(Map<String, Object> corpo, String campo) {
        String valor = texto(corpo, campo, 60);
        if (!valor.matches("[a-zA-Z0-9._-]{1,60}")) throw new IllegalArgumentException("ID invalido: " + campo);
        return valor;
    }

    private static String texto(Map<String, Object> corpo, String campo, int limite) { return texto(corpo, campo, limite, false); }

    private static String texto(Map<String, Object> corpo, String campo, int limite, boolean podeVazio) {
        Object valor = corpo.get(campo);
        if (!(valor instanceof String)) throw new IllegalArgumentException("Campo obrigatorio: " + campo);
        String texto = ((String) valor).trim();
        if ((texto.isEmpty() && !podeVazio) || texto.length() > limite) throw new IllegalArgumentException("Campo obrigatorio ou muito longo: " + campo);
        return texto;
    }

    private static double numero(Object valor, String campo) {
        if (!(valor instanceof Number)) throw new IllegalArgumentException("Campo deve ser numero: " + campo);
        return ((Number) valor).doubleValue();
    }

    private static int inteiro(Object valor) { return valor instanceof Number ? ((Number) valor).intValue() : 0; }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> listaDeMapas(Object valor) {
        List<Map<String, Object>> itens = new ArrayList<>();
        if (valor instanceof List) {
            for (Object item : (List<?>) valor) if (item instanceof Map) itens.add((Map<String, Object>) item);
        }
        return itens;
    }

    private static Map<String, Object> existente(Colecao colecao, String id, String mensagem) {
        Map<String, Object> documento = colecao.buscar(id);
        if (documento == null) throw new NaoEncontrado(mensagem);
        return documento;
    }

    private static void gravar(Colecao colecao, String id, Map<String, Object> documento) {
        if (!colecao.substituir(id, documento)) throw new NaoEncontrado("Registro removido durante a operacao");
    }

    private static void enviar(RespostaHttp resp, int codigo, Map<String, Object> corpo) throws IOException {
        resp.adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        resp.enviar(codigo, Json.escrever(corpo));
    }

    private static void erro(RespostaHttp resp, int codigo, String mensagem) throws IOException {
        resp.adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        resp.enviar(codigo, "{\"erro\":" + JsonSimples.escapar(mensagem) + "}");
    }
}
