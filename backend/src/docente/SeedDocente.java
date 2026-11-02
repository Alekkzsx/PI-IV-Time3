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

    static Map<String, Object> unidade(long numero, String titulo) { return mapa("unitNumber", numero, "title", titulo); }

    static Map<String, Object> material(String id, String titulo, String data, String tamanho, String tipo) {
        return mapa("id", id, "title", titulo, "date", data, "size", tamanho, "type", tipo);
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
                "professorIdentity", DOCENTE, "fullName", "Helena Bittencourt", "socialName", "Helena", "registrationId", "2324324",
                "department", "Departamento de Computação e Sistemas de Informação",
                "semester", "Corpo Docente Titular (2026/2)", "campus", "Campus Central - Polo Tecnológico Asa Norte",
                "status", "MATRÍCULA REGULAR", "academicEmail", "helena.bittencourt@docente.universidade.edu.br",
                "personalEmail", "h.bittencourt@email.com", "twoFactorEnabled", true));

        Colecao cursos = banco.colecao(DocenteEsquemas.CURSOS);
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "APS2-4N", mapa(
                "professorIdentity", DOCENTE, "classCode", "APS2-4N", "title", "Análise e Projeto de Sistemas II",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Lab Informática 04 - Bloco C",
                "schedule", "Segundas e Quartas, 19:10 - 20:50", "enrolledCount", 34L, "completedHours", 54L, "totalHours", 80L,
                "syllabusUnits", lista(
                        unidade(1, "Arquitetura em Camadas e Padrões Arquiteturais"),
                        unidade(2, "Modelagem Dinâmica e Interação Estruturada em UML 2.5"),
                        unidade(3, "Padrões de Criação e Comportamentais (GoF)"),
                        unidade(4, "Documentação Arquitetural e Entrega de Projeto Integrador")),
                "materials", lista(
                        material("mat-1", "Plano de Ensino 2026/2 e Cronograma Homologado", "10/08/2026", "1.2 MB", "PDF"),
                        material("mat-2", "Apostila de Padrões GRASP e Diagrama de Interação", "12/09/2026", "4.8 MB", "PDF"))));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "BD2-4N", mapa(
                "professorIdentity", DOCENTE, "classCode", "BD2-4N", "title", "Estudos de Banco de Dados II",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Lab Banco de Dados 02 - Bloco B",
                "schedule", "Terças e Quintas, 21:00 - 22:40", "enrolledCount", 31L, "completedHours", 60L, "totalHours", 80L,
                "syllabusUnits", lista(unidade(1, "Normalização Avançada (3FN e BCNF)"), unidade(2, "Otimização e Planos de Execução")),
                "materials", lista()));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "FSO-4N", mapa(
                "professorIdentity", DOCENTE, "classCode", "FSO-4N", "title", "Fundamentos de Sistemas Operacionais",
                "term", "2026/2 - 4º Semestre", "shift", "Noturno", "room", "Anfiteatro 101 - Bloco Central",
                "schedule", "Sextas-feiras, 19:10 - 22:40", "enrolledCount", 36L, "completedHours", 44L, "totalHours", 80L,
                "syllabusUnits", lista(unidade(1, "Gerenciamento de Processos e Threads"), unidade(2, "Gerenciamento de Memória Virtual")),
                "materials", lista()));

        Colecao tarefas = banco.colecao(DocenteEsquemas.TAREFAS);
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-1", mapa(
                "classCode", "APS2-4N", "title", "Entrega: Diagrama de Classes e Sequência", "weight", 3.0,
                "stage", "N1", "dueDate", "Hoje, 20/09 às 23:59", "isUrgent", true,
                "modality", "Trabalho em Grupo (Até 4 integrantes)", "allowLateWithPenalty", true,
                "rubricCriteria", lista(
                        mapa("id", "rc-1", "title", "Estruturação do Diagrama de Classes"),
                        mapa("id", "rc-2", "title", "Consistência do Diagrama de Sequência"),
                        mapa("id", "rc-3", "title", "Normas Técnicas e Clareza Conceitual"))));
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-2", mapa(
                "classCode", "BD2-4N", "title", "Atividade Prática: Modelagem Relacional e Normalização", "weight", 2.5,
                "stage", "N1", "dueDate", "24/09/2026 às 23:59", "isUrgent", false,
                "modality", "Trabalho Individual", "allowLateWithPenalty", false,
                "rubricCriteria", lista(
                        mapa("id", "rc-bd-1", "title", "Normalização em 3FN e BCNF"),
                        mapa("id", "rc-bd-2", "title", "Script DDL em PostgreSQL"))));

        total += gravar(banco.colecao(DocenteEsquemas.NOTAS), DocenteEsquemas.ESQUEMA_NOTAS, "nota-st-1", mapa(
                "classCode", "APS2-4N", "studentId", "st-1", "ra", "2024.1.00892", "studentName", "Gabriel Soares de Oliveira",
                "assignmentsScore", 9.0, "p1Score", 8.5, "projectsScore", 8.8, "p2Score", 9.0, "attendanceRate", 94.8));

        Colecao eventos = banco.colecao(DocenteEsquemas.EVENTOS);
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-1", mapa(
                "title", "Aula Presencial: Padrões GRASP e Diagrama de Sequência", "date", "2026-09-30",
                "time", "19:10 - 20:50", "type", "aula", "location", "Lab 04 - Bloco C"));
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-2", mapa(
                "title", "Encerramento de Prazo: Diagrama de Classes e Sequência", "date", "2026-09-30",
                "time", "23:59", "type", "avaliacao", "location", "Ambiente Virtual AVA"));

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
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "sala-aps2", mapa(
                "code", "SALA-APS2", "title", "APS-II - Aula ao vivo", "professorIdentity", DOCENTE, "classCode", "APS2-4N", "status", "SCHEDULED"));
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "sala-bd2", mapa(
                "code", "SALA-BD2", "title", "BD-II - Plantão de dúvidas", "professorIdentity", DOCENTE, "classCode", "BD2-4N", "status", "SCHEDULED"));
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
