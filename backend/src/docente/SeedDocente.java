// Desenvolvido por Marcelo Zarpelon

package docente;

import api.Esquema;
import database.BancoDados;
import database.BancoMemoria;
import database.BancoMongo;
import database.Colecao;
import database.IdDuplicadoException;
import database.MongoDBConnection;
import utils.ConfigEnv;
import videocall.VideoCallEsquemas;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Popula o banco com os dados do docente (os mesmos de DocenteMockData no frontend) e salas de exemplo.
// Sem argumentos faz so um ensaio em memoria; com --confirmar grava no MongoDB configurado em MONGODB_URI.
// Pode rodar varias vezes: documentos existentes sao substituidos pelo mesmo id.
public class SeedDocente {
    static final String DOCENTE = "prof.demo";

    static Map<String, Object> mapa(Object... pares) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < pares.length; i += 2) m.put((String) pares[i], pares[i + 1]);
        return m;
    }

    static List<Object> lista(Object... itens) {
        List<Object> l = new ArrayList<>();
        for (Object item : itens) l.add(item);
        return l;
    }

    static Map<String, Object> unidade(String id, long numero, String titulo, long feitas, long total) {
        return mapa("id", id, "unitNumber", numero, "title", titulo, "topics", lista(), "completedClasses", feitas, "totalClasses", total);
    }

    static Map<String, Object> material(String id, String cursoId, String titulo, String data, String tamanho, String tipo) {
        return mapa("id", id, "courseId", cursoId, "title", titulo, "date", data, "size", tamanho, "type", tipo);
    }

    static Map<String, Object> aluno(String id, String ra, String nome, String status, long faltas, double taxa, String risco) {
        return mapa("studentId", id, "ra", ra, "name", nome, "status", status, "accumulatedAbsences", faltas,
                "maxAbsences", 40L, "attendanceRate", taxa, "riskLevel", risco, "isConnected", false);
    }

    static Map<String, Object> sessaoAtiva(String id, String dispositivo, String local, String ip, String ultimo, boolean atual) {
        return mapa("id", id, "device", dispositivo, "location", local, "ip", ip, "lastActive", ultimo, "isCurrent", atual);
    }

    static Map<String, Object> acesso(String data, String hora, String dispositivo, String local, String ip, String status) {
        return mapa("date", data, "time", hora, "device", dispositivo, "location", local, "ip", ip, "status", status);
    }

    static Map<String, Object> criterio(String id, String titulo, double maximo) {
        return mapa("id", id, "title", titulo, "maxPoints", maximo, "description", "");
    }

    // Grava o documento; se o id ja existir, substitui (seed repetivel).
    static int gravar(Colecao colecao, Esquema esquema, String id, Map<String, Object> campos) {
        Map<String, Object> documento = new LinkedHashMap<>();
        documento.put("id", id);
        documento.putAll(esquema.validar(campos, false));
        try {
            colecao.inserir(documento);
        } catch (IdDuplicadoException e) {
            colecao.substituir(id, documento);
        }
        return 1;
    }

    public static int popular(BancoDados banco) {
        int total = 0;
        total += gravar(banco.colecao(DocenteEsquemas.DOCENTES), DocenteEsquemas.ESQUEMA_DOCENTES, DOCENTE, mapa(
                "teacherIdentity", DOCENTE, "fullName", "Helena Bittencourt", "socialName", "Helena", "registrationId", "2324324",
                "department", "Departamento de Computação e Sistemas de Informação",
                "semester", "Corpo Docente Titular (2026/2)", "campus", "Campus Central - Polo Tecnológico Asa Norte",
                "status", "MATRÍCULA REGULAR", "academicEmail", "helena.bittencourt@docente.universidade.edu.br",
                "personalEmail", "h.bittencourt@email.com", "twoFactorEnabled", true,
                "activeSessions", lista(
                        sessaoAtiva("sess-1", "Google Chrome 128.0 (Windows 11)", "São Paulo, SP - Brasil", "177.136.***.42", "Sessão Atual (Ativa agora)", true),
                        sessaoAtiva("sess-2", "Safari Mobile 17.5 (Apple iPhone 15)", "São Paulo, SP - Brasil", "189.40.***.118", "Há 2 horas", false),
                        sessaoAtiva("sess-3", "Mozilla Firefox 129.0 (Ubuntu Linux 24.04)", "Campinas, SP - Brasil", "201.82.***.93", "Ontem às 18:45", false)),
                "loginAudits", lista(
                        acesso("22/09/2026", "08:14", "Chrome / Windows 11", "São Paulo, Brasil", "177.136.***.42", "Autorizado"),
                        acesso("21/09/2026", "20:30", "Safari / iPhone 15", "São Paulo, Brasil", "189.40.***.118", "Autorizado"),
                        acesso("21/09/2026", "18:45", "Firefox / Linux", "Campinas, Brasil", "201.82.***.93", "Autorizado"))));

        Colecao cursos = banco.colecao(DocenteEsquemas.CURSOS);
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-aps2", mapa(
                "teacherIdentity", DOCENTE, "code", "218131 - APS-II", "title", "Análise e Projeto de Sistemas II",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Lab Informática 04 - Bloco C",
                "schedule", "Segundas e Quartas, 19:10 - 20:50", "enrolledCount", 34L, "completedHours", 54L, "totalHours", 80L,
                "syllabusUnits", lista(
                        unidade("unit-1", 1, "Arquitetura em Camadas e Padrões Arquiteturais", 10, 10),
                        unidade("unit-2", 2, "Modelagem Dinâmica e Interação Estruturada em UML 2.5", 8, 12),
                        unidade("unit-3", 3, "Padrões de Criação e Comportamentais (GoF)", 0, 12),
                        unidade("unit-4", 4, "Documentação Arquitetural e Entrega de Projeto Integrador", 0, 8)),
                "materials", lista(
                        material("mat-1", "course-aps2", "Plano de Ensino 2026/2 e Cronograma Homologado", "10/08/2026", "1.2 MB", "PDF"),
                        material("mat-2", "course-aps2", "Apostila de Padrões GRASP e Diagrama de Interação", "12/09/2026", "4.8 MB", "PDF"))));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-bd2", mapa(
                "teacherIdentity", DOCENTE, "code", "218131 - BD-II", "title", "Estudos de Banco de Dados II",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Lab Banco de Dados 02 - Bloco B",
                "schedule", "Terças e Quintas, 21:00 - 22:40", "enrolledCount", 31L, "completedHours", 60L, "totalHours", 80L,
                "syllabusUnits", lista(
                        unidade("unit-bd-1", 1, "Normalização Avançada (3FN e BCNF)", 0, 10),
                        unidade("unit-bd-2", 2, "Otimização e Planos de Execução", 0, 10)),
                "materials", lista()));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-fso", mapa(
                "teacherIdentity", DOCENTE, "code", "218131 - FSO", "title", "Fundamentos de Sistemas Operacionais",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Anfiteatro 101 - Bloco Central",
                "schedule", "Sextas-feiras, 19:10 - 22:40", "enrolledCount", 36L, "completedHours", 44L, "totalHours", 80L,
                "syllabusUnits", lista(
                        unidade("unit-fso-1", 1, "Gerenciamento de Processos e Threads", 0, 10),
                        unidade("unit-fso-2", 2, "Gerenciamento de Memória Virtual", 0, 10)),
                "materials", lista()));

        total += gravar(banco.colecao(DocenteEsquemas.AULAS), DocenteEsquemas.ESQUEMA_AULAS, "sess-27", mapa(
                "courseId", "course-aps2", "sessionNumber", 27L, "hours", 2L, "date", "2026-09-30",
                "dateFormatted", "30 de Setembro de 2026 (Quarta-feira)",
                "contentProgram", "Detalhamento do Diagrama de Sequência em UML 2.5: troca de mensagens síncronas, objetos ativados, fragmentos combinados (alt, loop, opt) e tratamento de exceções.",
                "methodology", "Aula expositiva dialogada e estudo de caso prático no laboratório de informática.",
                "location", "Lab Informática 04 - Bloco C", "isHomologated", false,
                "attendanceList", lista(
                        aluno("st-1", "2024.1.00892", "Gabriel Soares de Oliveira", "presente", 2, 94.7, "regular"),
                        aluno("st-2", "2024.1.00901", "Mariana Rios Costa", "presente", 1, 97.4, "regular"),
                        aluno("st-3", "2024.1.00915", "Lucas Mendes Santos", "ausente", 9, 76.3, "atencao"),
                        aluno("st-4", "2024.1.00922", "Beatriz Lima Alencar", "presente", 3, 92.1, "regular"),
                        aluno("st-5", "2024.1.00938", "Rodrigo Antunes Nogueira", "ausente", 12, 68.4, "critico"),
                        aluno("st-6", "2024.1.00944", "Juliana Paiva Castilho", "presente", 0, 100.0, "regular"),
                        aluno("st-7", "2024.1.00959", "Thiago Farias Barreto", "presente", 4, 89.5, "regular"))));

        Colecao tarefas = banco.colecao(DocenteEsquemas.TAREFAS);
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-1", mapa(
                "courseId", "course-aps2", "courseCode", "218131 - APS-II", "title", "Entrega: Diagrama de Classes e Sequência",
                "weight", 3.0, "stage", "N1", "dueDateFormatted", "Hoje, 20/09 às 23:59", "isUrgent", true,
                "modality", "Trabalho em Grupo (Até 4 integrantes)", "allowLateWithPenalty", true,
                "rubricCriteria", lista(
                        criterio("rc-1", "Estruturação do Diagrama de Classes", 4.0),
                        criterio("rc-2", "Consistência do Diagrama de Sequência", 3.0),
                        criterio("rc-3", "Normas Técnicas e Clareza Conceitual", 3.0)),
                "submissions", lista(mapa("id", "sub-1", "studentId", "st-1", "ra", "2024.1.00892",
                        "studentName", "Gabriel Soares de Oliveira", "status", "aguardandoCorrecao", "rubricEvaluations", lista()))));
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-2", mapa(
                "courseId", "course-bd2", "courseCode", "218131 - BD-II", "title", "Atividade Prática: Modelagem Relacional e Normalização",
                "weight", 2.5, "stage", "N1", "dueDateFormatted", "24/09/2026 às 23:59", "isUrgent", false,
                "modality", "Trabalho Individual", "allowLateWithPenalty", false,
                "rubricCriteria", lista(
                        criterio("rc-bd-1", "Normalização em 3FN e BCNF", 5.0),
                        criterio("rc-bd-2", "Script DDL em PostgreSQL", 5.0)),
                "submissions", lista()));

        total += gravar(banco.colecao(DocenteEsquemas.NOTAS), DocenteEsquemas.ESQUEMA_NOTAS, "grade-st-1", mapa(
                "courseId", "course-aps2", "studentId", "st-1", "ra", "2024.1.00892", "studentName", "Gabriel Soares de Oliveira",
                "assignmentsScore", 9.0, "p1Score", 8.5, "projectsScore", 8.8, "p2Score", 9.0, "attendanceRate", 94.8));

        Colecao eventos = banco.colecao(DocenteEsquemas.EVENTOS);
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-1", mapa(
                "title", "Aula Presencial: Padrões GRASP e Diagrama de Sequência", "date", "2026-09-30",
                "time", "19:10 - 20:50", "type", "aula", "location", "Lab 04 - Bloco C", "isSynced", true));
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-2", mapa(
                "title", "Encerramento de Prazo: Diagrama de Classes e Sequência", "date", "2026-09-30",
                "time", "23:59", "type", "avaliacao", "location", "Ambiente Virtual AVA", "isSynced", true));

        Colecao avisos = banco.colecao(DocenteEsquemas.AVISOS);
        total += gravar(avisos, DocenteEsquemas.ESQUEMA_AVISOS, "not-sec-1", mapa(
                "author", "Secretaria Geral Acadêmica (ADM-00129)", "targetCourse", "Institucional Geral",
                "targetAudience", "Corpo Docente e Discente", "classification", "informativo", "publishedAt", "18/09/2026",
                "title", "Período Oficial de Validação de Atividades Complementares 2026/2",
                "message", "A Secretaria Geral Acadêmica informa que o prazo para submissão de certificados e cursos de extensão para cômputo de horas complementares encerra-se em 30 de novembro.",
                "readCount", 101L, "totalRecipients", 101L, "isFromSecretaria", true));
        total += gravar(avisos, DocenteEsquemas.ESQUEMA_AVISOS, "not-sec-2", mapa(
                "author", "Diretoria de Tecnologia e Informação (DTI)", "targetCourse", "Infraestrutura AVA",
                "targetAudience", "Todos os Usuários", "classification", "urgencia", "publishedAt", "15/09/2026",
                "title", "Manutenção Preventiva dos Ambientes Virtuais de Aprendizagem",
                "message", "No próximo sábado, das 02:00 às 05:00, os servidores de banco de dados do AVA passarão por otimização técnica. Não haverá impacto nas entregas programadas.",
                "readCount", 101L, "totalRecipients", 101L, "isFromSecretaria", true));

        Colecao salas = banco.colecao(VideoCallEsquemas.SALAS);
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "room-aps2", mapa(
                "code", "SALA-APS2", "title", "APS-II - Aula ao vivo", "professorIdentity", DOCENTE,
                "classCode", "course-aps2", "status", "SCHEDULED"));
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "room-bd2", mapa(
                "code", "SALA-BD2", "title", "BD-II - Plantão de dúvidas", "professorIdentity", DOCENTE,
                "classCode", "course-bd2", "status", "SCHEDULED"));
        return total;
    }

    public static void main(String[] args) {
        boolean confirmar = args.length > 0 && args[0].equals("--confirmar");
        BancoDados banco;
        if (confirmar) {
            ConfigEnv.exigir("MONGODB_URI");
            banco = new BancoMongo(MongoDBConnection.conectar());
        } else {
            System.out.println("[SEED] Ensaio em memoria. Use --confirmar para gravar no MongoDB.");
            banco = new BancoMemoria();
        }
        try {
            System.out.println("[SEED] " + popular(banco) + " documentos gravados" + (confirmar ? " no MongoDB" : " (ensaio)"));
        } finally {
            if (confirmar) MongoDBConnection.fechar();
        }
    }
}
