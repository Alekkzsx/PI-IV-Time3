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
    static final String DOCENTE = "doc-helena";

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

    static Map<String, Object> unidade(long numero, String titulo) { return mapa("numero", numero, "titulo", titulo); }

    static Map<String, Object> material(String id, String titulo, String data, String tamanho, String tipo) {
        return mapa("id", id, "titulo", titulo, "data", data, "tamanho", tamanho, "tipo", tipo);
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
                "nomeCompleto", "Helena Bittencourt", "nomeSocial", "Helena", "matricula", "2324324",
                "departamento", "Departamento de Computação e Sistemas de Informação",
                "semestre", "Corpo Docente Titular (2026/2)", "campus", "Campus Central - Polo Tecnológico Asa Norte",
                "status", "MATRÍCULA REGULAR", "emailAcademico", "helena.bittencourt@docente.universidade.edu.br",
                "emailPessoal", "h.bittencourt@email.com", "doisFatores", true));

        Colecao cursos = banco.colecao(DocenteEsquemas.CURSOS);
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-aps2", mapa(
                "docenteId", DOCENTE, "codigo", "218131 - APS-II", "titulo", "Análise e Projeto de Sistemas II",
                "periodo", "2026/2 - 4º Semestre", "turno", "Noturno", "sala", "Lab Informática 04 - Bloco C",
                "horario", "Segundas e Quartas, 19:10 - 20:50", "matriculados", 34L, "horasConcluidas", 54L, "horasTotais", 80L,
                "unidades", lista(
                        unidade(1, "Arquitetura em Camadas e Padrões Arquiteturais"),
                        unidade(2, "Modelagem Dinâmica e Interação Estruturada em UML 2.5"),
                        unidade(3, "Padrões de Criação e Comportamentais (GoF)"),
                        unidade(4, "Documentação Arquitetural e Entrega de Projeto Integrador")),
                "materiais", lista(
                        material("mat-1", "Plano de Ensino 2026/2 e Cronograma Homologado", "10/08/2026", "1.2 MB", "PDF"),
                        material("mat-2", "Apostila de Padrões GRASP e Diagrama de Interação", "12/09/2026", "4.8 MB", "PDF"))));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-bd2", mapa(
                "docenteId", DOCENTE, "codigo", "218131 - BD-II", "titulo", "Estudos de Banco de Dados II",
                "periodo", "2026/2 - 4º Semestre", "turno", "Noturno", "sala", "Lab Banco de Dados 02 - Bloco B",
                "horario", "Terças e Quintas, 21:00 - 22:40", "matriculados", 31L, "horasConcluidas", 60L, "horasTotais", 80L,
                "unidades", lista(unidade(1, "Normalização Avançada (3FN e BCNF)"), unidade(2, "Otimização e Planos de Execução")),
                "materiais", lista()));
        total += gravar(cursos, DocenteEsquemas.ESQUEMA_CURSOS, "course-fso", mapa(
                "docenteId", DOCENTE, "codigo", "218131 - FSO", "titulo", "Fundamentos de Sistemas Operacionais",
                "periodo", "2026/2 - 4º Semestre", "turno", "Noturno", "sala", "Anfiteatro 101 - Bloco Central",
                "horario", "Sextas-feiras, 19:10 - 22:40", "matriculados", 36L, "horasConcluidas", 44L, "horasTotais", 80L,
                "unidades", lista(unidade(1, "Gerenciamento de Processos e Threads"), unidade(2, "Gerenciamento de Memória Virtual")),
                "materiais", lista()));

        Colecao tarefas = banco.colecao(DocenteEsquemas.TAREFAS);
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-1", mapa(
                "cursoId", "course-aps2", "titulo", "Entrega: Diagrama de Classes e Sequência", "peso", 3.0,
                "etapa", "N1", "prazo", "Hoje, 20/09 às 23:59", "urgente", true,
                "modalidade", "Trabalho em Grupo (Até 4 integrantes)", "permiteAtraso", true,
                "criterios", lista(
                        mapa("id", "rc-1", "titulo", "Estruturação do Diagrama de Classes"),
                        mapa("id", "rc-2", "titulo", "Consistência do Diagrama de Sequência"),
                        mapa("id", "rc-3", "titulo", "Normas Técnicas e Clareza Conceitual"))));
        total += gravar(tarefas, DocenteEsquemas.ESQUEMA_TAREFAS, "asg-2", mapa(
                "cursoId", "course-bd2", "titulo", "Atividade Prática: Modelagem Relacional e Normalização", "peso", 2.5,
                "etapa", "N1", "prazo", "24/09/2026 às 23:59", "urgente", false,
                "modalidade", "Trabalho Individual", "permiteAtraso", false,
                "criterios", lista(
                        mapa("id", "rc-bd-1", "titulo", "Normalização em 3FN e BCNF"),
                        mapa("id", "rc-bd-2", "titulo", "Script DDL em PostgreSQL"))));

        total += gravar(banco.colecao(DocenteEsquemas.NOTAS), DocenteEsquemas.ESQUEMA_NOTAS, "nota-st-1", mapa(
                "cursoId", "course-aps2", "alunoId", "st-1", "ra", "2024.1.00892", "aluno", "Gabriel Soares de Oliveira",
                "tarefas", 9.0, "p1", 8.5, "projetos", 8.8, "p2", 9.0, "frequencia", 94.8));

        Colecao eventos = banco.colecao(DocenteEsquemas.EVENTOS);
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-1", mapa(
                "titulo", "Aula Presencial: Padrões GRASP e Diagrama de Sequência", "data", "2026-09-30",
                "horario", "19:10 - 20:50", "tipo", "aula", "local", "Lab 04 - Bloco C"));
        total += gravar(eventos, DocenteEsquemas.ESQUEMA_EVENTOS, "ev-2", mapa(
                "titulo", "Encerramento de Prazo: Diagrama de Classes e Sequência", "data", "2026-09-30",
                "horario", "23:59", "tipo", "avaliacao", "local", "Ambiente Virtual AVA"));

        Colecao avisos = banco.colecao(DocenteEsquemas.AVISOS);
        total += gravar(avisos, DocenteEsquemas.ESQUEMA_AVISOS, "not-sec-1", mapa(
                "autor", "Secretaria Geral Acadêmica (ADM-00129)", "cursoAlvo", "Institucional Geral",
                "publicoAlvo", "Corpo Docente e Discente", "classificacao", "informativo", "publicadoEm", "18/09/2026",
                "titulo", "Período Oficial de Validação de Atividades Complementares 2026/2",
                "mensagem", "A Secretaria Geral Acadêmica informa que o prazo para submissão de certificados e cursos de extensão para cômputo de horas complementares encerra-se em 30 de novembro.",
                "lidos", 101L, "destinatarios", 101L, "daSecretaria", true));
        total += gravar(avisos, DocenteEsquemas.ESQUEMA_AVISOS, "not-sec-2", mapa(
                "autor", "Diretoria de Tecnologia e Informação (DTI)", "cursoAlvo", "Infraestrutura AVA",
                "publicoAlvo", "Todos os Usuários", "classificacao", "urgencia", "publicadoEm", "15/09/2026",
                "titulo", "Manutenção Preventiva dos Ambientes Virtuais de Aprendizagem",
                "mensagem", "No próximo sábado, das 02:00 às 05:00, os servidores de banco de dados do AVA passarão por otimização técnica. Não haverá impacto nas entregas programadas.",
                "lidos", 101L, "destinatarios", 101L, "daSecretaria", true));

        Colecao salas = banco.colecao(VideoCallEsquemas.SALAS);
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "sala-aps2", mapa(
                "codigo", "SALA-APS2", "titulo", "APS-II - Aula ao vivo", "docenteId", DOCENTE, "cursoId", "course-aps2", "status", "AGENDADA"));
        total += gravar(salas, VideoCallEsquemas.ESQUEMA_SALAS, "sala-bd2", mapa(
                "codigo", "SALA-BD2", "titulo", "BD-II - Plantão de dúvidas", "docenteId", DOCENTE, "cursoId", "course-bd2", "status", "AGENDADA"));
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
