// Desenvolvido por Time 3 AGMRM — PI-IV (PUC-Campinas 2026)
// Equipe: Alex Gabriel (24802449), Guilherme Moreira (25006702),
//         Marcelo Zarpelon (25015323), Murillo Caravita (25014012), Rafael Inacio (25009719)

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import videocall.modules.legado.VideoCallService;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Teste Unitario INTRACLASSE — Classe de Dominio: {@link VideoCallService}.
 *
 * Abordagem de Particionamento Adotada: PARTICIONAMENTO POR ESTADOS.
 * Justificativa: A classe orquestra o ciclo de vida completo de uma sala de aula virtual
 * com transicoes de estado dependentes de papel (RBAC), participantes ativos, fila FIFO
 * de maos levantadas, caixa de sinalizacao WebRTC (drain) e calculo de presenca.
 */
@DisplayName("Intraclasse [ESTADOS] — VideoCallService")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class IntraclasseVideoCallServiceTest {

    private VideoCallService service;
    private String codigoSala;

    @BeforeEach
    void prepararSalaIsolada() {
        service = VideoCallService.getInstance();
        codigoSala = "SALA-TEST-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    @Test
    @Order(1)
    @DisplayName("Seq 1 [FECHADA -> RECUSA_ALUNO -> ABERTA_DOCENTE]: Controle de abertura por papel")
    void seq1ControleAberturaPorPapel() {
        VideoCallService.Room sala = service.obterOuCriarSala(codigoSala);
        assertFalse(sala.isOpen, "Sala recem-criada deve iniciar no estado FECHADA");
        assertEquals(0, sala.getTotalDurationMinutes(), "Sala nunca aberta tem duracao 0");

        assertFalse(service.abrirSala(codigoSala, "aluno", "Gabriel"),
                "Aluno nao deve ter permissao para abrir sala");
        assertFalse(service.entrarNaSala(codigoSala, "24802449", "Gabriel", "aluno"),
                "Aluno nao deve entrar em sala fechada");
        assertFalse(sala.isOpen);

        assertTrue(service.abrirSala(codigoSala, "docente", "Prof. Renata"),
                "Docente deve conseguir abrir a sala");
        assertTrue(sala.isOpen);
        assertEquals("docente", sala.openedByRole);
        assertEquals("Prof. Renata", sala.openedByName);
        assertTrue(sala.getTotalDurationMinutes() >= 1);
    }

    @Test
    @Order(2)
    @DisplayName("Seq 2 [ABERTA -> PARTICIPANTES -> SINALIZACAO -> SAIDA]: Peer-joined, drain WebRTC e peer-left")
    void seq2EntradaSinalizacaoDrainESaida() {
        assertTrue(service.entrarNaSala(codigoSala, "DOC-01", "Prof. Renata", "docente"));
        assertTrue(service.entrarNaSala(codigoSala, "24802449", "Alex", "aluno"));

        VideoCallService.Room sala = service.obterOuCriarSala(codigoSala);
        assertEquals(2, sala.activeParticipants.size());
        assertEquals(2, sala.attendanceHistory.size());

        List<VideoCallService.SignalingMessage> sinaisDocente = service.buscarSinalizacoes(codigoSala, "DOC-01");
        assertEquals(1, sinaisDocente.size(), "Docente deve receber evento peer-joined do aluno");
        assertEquals("peer-joined", sinaisDocente.get(0).type);
        assertEquals("24802449", sinaisDocente.get(0).fromRa);

        assertTrue(service.buscarSinalizacoes(codigoSala, "DOC-01").isEmpty(),
                "buscarSinalizacoes() deve drenar a caixa de sinalizacao");

        service.enviarSinalizacao(codigoSala, "DOC-01", "24802449", "offer", "{\"sdp\":\"v=0...\"}");
        List<VideoCallService.SignalingMessage> sinaisAluno = service.buscarSinalizacoes(codigoSala, "24802449");
        assertEquals(1, sinaisAluno.size());
        assertEquals("offer", sinaisAluno.get(0).type);

        service.sairDaSala(codigoSala, "24802449");
        assertEquals(1, sala.activeParticipants.size());
        assertEquals(2, sala.attendanceHistory.size(), "Historico de presenca e append-only");
        assertTrue(sala.attendanceHistory.get(1).leftAt > 0, "leftAt deve ser carimbado na saida");
        assertTrue(sala.attendanceHistory.get(1).getConnectedMinutes() >= 1);

        List<VideoCallService.SignalingMessage> posSaida = service.buscarSinalizacoes(codigoSala, "DOC-01");
        assertEquals(1, posSaida.size());
        assertEquals("peer-left", posSaida.get(0).type);
    }

    @Test
    @Order(3)
    @DisplayName("Seq 3 [INTERACAO_ATIVA -> ENCERRADA]: Fila FIFO de maos levantadas, chat e fechamento")
    void seq3FilaFifoMaosChatEFechamento() {
        service.abrirSala(codigoSala, "admin", "Coordenacao");
        service.entrarNaSala(codigoSala, "24802449", "Alex", "aluno");
        service.entrarNaSala(codigoSala, "25009719", "Rafael", "aluno");

        assertTrue(service.alternarMaoLevantada(codigoSala, "24802449", true));
        assertTrue(service.alternarMaoLevantada(codigoSala, "24802449", true), "Chamada idempotente nao duplica na fila");
        assertTrue(service.alternarMaoLevantada(codigoSala, "25009719", true));

        VideoCallService.Room sala = service.obterOuCriarSala(codigoSala);
        assertEquals(2, sala.handRaiseQueue.size());
        assertEquals("24802449", sala.handRaiseQueue.get(0), "Ordem FIFO deve manter o primeiro a levantar a mao");
        assertEquals("25009719", sala.handRaiseQueue.get(1));

        assertTrue(service.alternarMaoLevantada(codigoSala, "24802449", false));
        assertEquals(1, sala.handRaiseQueue.size());
        assertEquals("25009719", sala.handRaiseQueue.get(0));

        assertFalse(service.alternarMaoLevantada(codigoSala, "RA-INEXISTENTE", true));

        service.adicionarMensagemChat(codigoSala, "24802449", "Alex", "aluno", "Duvida no exercicio 3");
        assertEquals(1, sala.chatHistory.size());
        assertTrue(sala.chatHistory.get(0).timeFormatted.matches("\\d{2}:\\d{2}:\\d{2}"));

        assertTrue(service.fecharSala(codigoSala, "admin"));
        assertFalse(sala.isOpen);
        assertTrue(sala.closedAt > 0);
        assertFalse(service.fecharSala(codigoSala, "admin"), "Fechar sala ja encerrada deve retornar false");
    }

    @Test
    @Order(4)
    @DisplayName("Seq 4 [DETECCAO DE ANOMALIA #6]: Evidencia falhas em roomCode vazio/null e RBAC em fecharSala")
    void seq4EvidenciaAnomaliasVideoCallService() {
        VideoCallService.Room salaNull = service.obterOuCriarSala(null);
        VideoCallService.Room salaVazia = service.obterOuCriarSala("   ");
        assertEquals("GERAL", salaNull.roomCode);
        assertEquals("", salaVazia.roomCode,
                "Evidencia da Anomalia #6a: espacos/vazio nao caem no fallback GERAL");

        service.abrirSala(codigoSala, "docente", "Prof. Renata");
        boolean alunoConseguiuFechar = service.fecharSala(codigoSala, "aluno");
        assertTrue(alunoConseguiuFechar,
                "Evidencia da Anomalia #6b: fecharSala() nao valida permissao do papel 'role'");

        assertThrows(NullPointerException.class, () -> service.fecharSala(null, "docente"),
                "Evidencia da Anomalia #6c: fecharSala(null, ...) lanca NPE sem validacao defensiva");
        assertThrows(NullPointerException.class, () -> service.sairDaSala(null, "24802449"),
                "Evidencia da Anomalia #6c: sairDaSala(null, ...) lanca NPE sem validacao defensiva");
    }
}
