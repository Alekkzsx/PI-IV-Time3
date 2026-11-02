// Desenvolvido por Marcelo Zarpelon

package docente;

import api.Campo;
import api.Esquema;

// Esquemas das colecoes do portal do docente.
// Os campos seguem exatamente os modelos de features/teacher/shared/domain/models no frontend, para que o
// app consuma o JSON sem traducao. As colecoes usam o prefixo do banco agmrm; classCode (opcional) liga o
// plano a uma turma de academic_classes e teacherIdentity liga ao login do professor em auth_users.
public final class DocenteEsquemas {
    private DocenteEsquemas() {}

    public static final String DOCENTES = "docente_profiles";
    // Plano da turma/curso: DocenteCourse no frontend (nome da constante mantido por compatibilidade).
    public static final String CURSOS = "docente_class_plans";
    public static final String AULAS = "docente_attendance_sessions";
    public static final String TAREFAS = "docente_assignments";
    public static final String NOTAS = "docente_grades";
    public static final String AVISOS = "docente_notices";
    public static final String EVENTOS = "docente_events";

    public static final String[] STATUS_PRESENCA = {"presente", "ausente", "justificada"};

    // DocenteProfile (activeSessions = ActiveSession, loginAudits = LoginAudit)
    public static final Esquema ESQUEMA_DOCENTES = new Esquema(
            Campo.texto("teacherIdentity", true, 60),
            Campo.texto("fullName", true, 120),
            Campo.texto("socialName", false, 120),
            Campo.texto("registrationId", true, 30),
            Campo.texto("department", true, 120),
            Campo.texto("semester", true, 60),
            Campo.texto("campus", true, 80),
            Campo.texto("status", true, 40),
            Campo.texto("academicEmail", true, 180),
            Campo.texto("personalEmail", false, 180),
            Campo.booleano("twoFactorEnabled", false),
            Campo.lista("activeSessions", false, 50),
            Campo.lista("loginAudits", false, 200));

    // DocenteCourse (syllabusUnits = SyllabusUnit, materials = CourseMaterial)
    public static final Esquema ESQUEMA_CURSOS = new Esquema(
            Campo.texto("teacherIdentity", true, 60),
            Campo.texto("classCode", false, 60),
            Campo.texto("code", true, 60),
            Campo.texto("title", true, 160),
            Campo.texto("term", true, 60),
            Campo.texto("shift", true, 30),
            Campo.texto("room", false, 120),
            Campo.texto("schedule", false, 120),
            Campo.inteiro("enrolledCount", true),
            Campo.inteiro("completedHours", false),
            Campo.inteiro("totalHours", true),
            Campo.lista("syllabusUnits", false, 50),
            Campo.lista("materials", false, 200));

    // ClassSession (attendanceList = AttendanceStudent)
    public static final Esquema ESQUEMA_AULAS = new Esquema(
            Campo.texto("courseId", true, 60),
            Campo.inteiro("sessionNumber", true),
            Campo.inteiro("hours", true),
            Campo.texto("date", false, 20),
            Campo.texto("dateFormatted", false, 80),
            Campo.texto("contentProgram", false, 600),
            Campo.texto("methodology", false, 400),
            Campo.texto("location", false, 120),
            Campo.booleano("isHomologated", false),
            Campo.lista("attendanceList", false, 500));

    // AssignmentItem (rubricCriteria = RubricCriterion, submissions = StudentSubmission)
    public static final Esquema ESQUEMA_TAREFAS = new Esquema(
            Campo.texto("courseId", true, 60),
            Campo.texto("courseCode", false, 60),
            Campo.texto("title", true, 160),
            Campo.texto("description", false, 1000),
            Campo.decimal("weight", true),
            Campo.texto("stage", false, 40),
            Campo.texto("dueDateFormatted", false, 60),
            Campo.booleano("isUrgent", false),
            Campo.texto("modality", false, 100),
            Campo.booleano("allowLateWithPenalty", false),
            Campo.lista("rubricCriteria", false, 50),
            Campo.lista("submissions", false, 500));

    // StudentGrade (n1Total, n2Total, finalAverage e status sao calculados pelo servidor)
    public static final Esquema ESQUEMA_NOTAS = new Esquema(
            Campo.texto("courseId", true, 60),
            Campo.texto("studentId", true, 60),
            Campo.texto("ra", true, 30),
            Campo.texto("studentName", true, 120),
            Campo.decimal("assignmentsScore", false),
            Campo.decimal("p1Score", false),
            Campo.decimal("projectsScore", false),
            Campo.decimal("p2Score", false),
            Campo.decimal("attendanceRate", false));

    // AcademicNotice
    public static final Esquema ESQUEMA_AVISOS = new Esquema(
            Campo.texto("author", true, 120),
            Campo.texto("targetCourse", true, 160),
            Campo.texto("targetAudience", true, 120),
            Campo.opcao("classification", true, "informativo", "urgencia", "convocacao"),
            Campo.texto("publishedAt", true, 40),
            Campo.texto("title", true, 160),
            Campo.texto("message", true, 2000),
            Campo.inteiro("readCount", false),
            Campo.inteiro("totalRecipients", false),
            Campo.booleano("isFromSecretaria", false));

    // AcademicEvent
    public static final Esquema ESQUEMA_EVENTOS = new Esquema(
            Campo.texto("title", true, 160),
            Campo.texto("date", true, 20),
            Campo.texto("time", false, 40),
            Campo.opcao("type", true, "aula", "avaliacao", "plantao", "colegiado", "reuniao"),
            Campo.texto("location", false, 120),
            Campo.booleano("isSynced", false));
}
