// Desenvolvido por Marcelo Zarpelon

package docente;

import api.Campo;
import api.Esquema;

// Esquemas das colecoes do portal do docente, espelhando os modelos de docente_view no frontend.
public final class DocenteEsquemas {
    private DocenteEsquemas() {}

    public static final String DOCENTES = "docentes";
    public static final String CURSOS = "cursos";
    public static final String AULAS = "aulas";
    public static final String TAREFAS = "tarefas";
    public static final String NOTAS = "notas";
    public static final String AVISOS = "avisos";
    public static final String EVENTOS = "eventos";

    // DocenteProfile
    public static final Esquema ESQUEMA_DOCENTES = new Esquema(
            Campo.texto("nomeCompleto", true, 120),
            Campo.texto("nomeSocial", false, 120),
            Campo.texto("matricula", true, 30),
            Campo.texto("departamento", true, 120),
            Campo.texto("semestre", true, 30),
            Campo.texto("campus", true, 80),
            Campo.texto("status", true, 20),
            Campo.texto("emailAcademico", true, 180),
            Campo.texto("emailPessoal", false, 180),
            Campo.booleano("doisFatores", false));

    // DocenteCourse (unidades = SyllabusUnit, materiais = CourseMaterial)
    public static final Esquema ESQUEMA_CURSOS = new Esquema(
            Campo.texto("docenteId", true, 60),
            Campo.texto("codigo", true, 60),
            Campo.texto("titulo", true, 160),
            Campo.texto("periodo", true, 60),
            Campo.texto("turno", true, 30),
            Campo.texto("sala", false, 120),
            Campo.texto("horario", false, 120),
            Campo.inteiro("matriculados", true),
            Campo.inteiro("horasConcluidas", false),
            Campo.inteiro("horasTotais", true),
            Campo.lista("unidades", false, 50),
            Campo.lista("materiais", false, 200));

    // ClassSession (frequencia = lista de AttendanceStudent)
    public static final Esquema ESQUEMA_AULAS = new Esquema(
            Campo.texto("cursoId", true, 60),
            Campo.inteiro("numero", true),
            Campo.inteiro("horas", true),
            Campo.texto("data", true, 20),
            Campo.texto("conteudo", false, 500),
            Campo.texto("metodologia", false, 300),
            Campo.booleano("homologada", false),
            Campo.lista("frequencia", false, 500));

    // AssignmentItem (criterios = RubricCriterion, entregas = StudentSubmission)
    public static final Esquema ESQUEMA_TAREFAS = new Esquema(
            Campo.texto("cursoId", true, 60),
            Campo.texto("titulo", true, 160),
            Campo.decimal("peso", true),
            Campo.texto("etapa", false, 40),
            Campo.texto("prazo", false, 40),
            Campo.booleano("urgente", false),
            Campo.texto("modalidade", false, 80),
            Campo.booleano("permiteAtraso", false),
            Campo.lista("criterios", false, 50),
            Campo.lista("entregas", false, 500));

    // StudentGrade
    public static final Esquema ESQUEMA_NOTAS = new Esquema(
            Campo.texto("cursoId", true, 60),
            Campo.texto("alunoId", true, 60),
            Campo.texto("ra", true, 30),
            Campo.texto("aluno", true, 120),
            Campo.decimal("tarefas", false),
            Campo.decimal("p1", false),
            Campo.decimal("projetos", false),
            Campo.decimal("p2", false),
            Campo.decimal("frequencia", false));

    // AcademicNotice
    public static final Esquema ESQUEMA_AVISOS = new Esquema(
            Campo.texto("autor", true, 120),
            Campo.texto("cursoAlvo", true, 160),
            Campo.texto("publicoAlvo", true, 120),
            Campo.texto("classificacao", true, 30),
            Campo.texto("publicadoEm", true, 40),
            Campo.texto("titulo", true, 160),
            Campo.texto("mensagem", true, 2000),
            Campo.inteiro("lidos", false),
            Campo.inteiro("destinatarios", false),
            Campo.booleano("daSecretaria", false));

    // AcademicEvent
    public static final Esquema ESQUEMA_EVENTOS = new Esquema(
            Campo.texto("titulo", true, 160),
            Campo.texto("data", true, 20),
            Campo.texto("horario", false, 40),
            Campo.texto("tipo", true, 30),
            Campo.texto("local", false, 120),
            Campo.booleano("sincronizado", false));
}
