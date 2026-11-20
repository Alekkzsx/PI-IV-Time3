// Desenvolvido por Time 3 AGMRM — PI-IV (PUC-Campinas 2026)
// Equipe: Alex Gabriel (24802449), Guilherme Moreira (25006702),
//         Marcelo Zarpelon (25015323), Murillo Caravita (25014012), Rafael Inacio (25009719)

import auth.utils.LimitadorTentativas;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Teste Unitario INTRACLASSE — Classe de Dominio: {@link LimitadorTentativas}.
 *
 * Abordagem de Particionamento Adotada: PARTICIONAMENTO POR ESTADOS.
 * Justificativa: A classe gerencia uma maquina de estados critica de ciberdefesa
 * contra forca bruta e credential stuffing com transicoes progressivas de bloqueio:
 *
 *   [LIVRE (0 falhas)]
 *        | registrarFalha() (1..4x)
 *        v
 *   [ALERTA (1..4 falhas)] --registrarSucesso()--> [LIVRE / RESETADO]
 *        | registrarFalha() (5a falha)
 *        v
 *   [BLOQUEADO_N1 (30s)]   --registrarFalha() (15a falha)--> [BLOQUEADO_N2 (5min)]
 *        |                                                          |
 *        | registrarSucesso() / expiracao                           | registrarFalha() (30a falha)
 *        v                                                          v
 *   [LIVRE / RESETADO]                                    [BLOQUEADO_N3 (30min)]
 */
@DisplayName("Intraclasse [ESTADOS] — LimitadorTentativas")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class IntraclasseLimitadorTentativasTest {

    private static String prevMaxTentativas;
    private static String prevLockoutSec;

    private LimitadorTentativas limitador;

    @BeforeAll
    static void configurarPropriedades() {
        prevMaxTentativas = System.getProperty("MAX_FAILED_LOGIN_ATTEMPTS");
        prevLockoutSec = System.getProperty("LOCKOUT_DURATION_SECONDS");
        System.setProperty("MAX_FAILED_LOGIN_ATTEMPTS", "5");
        System.setProperty("LOCKOUT_DURATION_SECONDS", "30");
    }

    @AfterAll
    static void restaurarPropriedades() {
        restaurar("MAX_FAILED_LOGIN_ATTEMPTS", prevMaxTentativas);
        restaurar("LOCKOUT_DURATION_SECONDS", prevLockoutSec);
    }

    private static void restaurar(String chave, String valor) {
        if (valor == null) {
            System.clearProperty(chave);
        } else {
            System.setProperty(chave, valor);
        }
    }

    @BeforeEach
    void prepararEstadoLimpo() {
        limitador = LimitadorTentativas.getInstance();
        limitador.limparTudo();
    }

    @Test
    @Order(1)
    @DisplayName("Seq 1 [LIVRE -> ALERTA -> LIVRE]: Permite tentativas ate 4 falhas e reseta no sucesso")
    void seq1EstadoLivreAlertaResetSucesso() {
        String ra = "24802449";
        String ip = "192.168.0.10";

        // Estado inicial: LIVRE
        assertTrue(limitador.permitirTentativa(ra, ip), "Estado inicial deve ser LIVRE");
        assertEquals(0L, limitador.segundosRestantesBloqueio(ra), "Sem bloqueio ativo no estado LIVRE");

        // Transicao LIVRE -> ALERTA (falhas 1 a 4)
        for (int tentativa = 1; tentativa <= 4; tentativa++) {
            String msg = limitador.registrarFalha(ra, ip);
            assertTrue(msg.contains("Tentativa " + tentativa + " de 5"),
                    "Mensagem deve indicar progresso da tentativa " + tentativa + ": " + msg);
            assertTrue(limitador.permitirTentativa(ra, ip),
                    "Estado ALERTA ainda deve permitir novas tentativas antes do limiar");
            assertEquals(0L, limitador.segundosRestantesBloqueio(ra));
        }

        // Transicao ALERTA -> LIVRE (via login bem-sucedido)
        limitador.registrarSucesso(ra, ip);
        assertTrue(limitador.permitirTentativa(ra, ip), "Apos sucesso, estado retorna para LIVRE");

        // Nova falha isolada deve recomecar em Tentativa 1 de 5 (prova de reset do contador)
        String msgPosReset = limitador.registrarFalha(ra, ip);
        assertTrue(msgPosReset.contains("Tentativa 1 de 5"),
                "Contador deve reiniciar em 1 apos registrarSucesso(): " + msgPosReset);
    }

    @Test
    @Order(2)
    @DisplayName("Seq 2 [LIVRE -> ALERTA -> BLOQUEADO_N1]: 5a falha dispara lockout base de 30s")
    void seq2TransicaoParaBloqueioNivel1() {
        String ra = "25006702";
        String ip = "10.0.0.21";

        for (int i = 1; i <= 4; i++) {
            limitador.registrarFalha(ra, ip);
        }
        String msgBloqueio = limitador.registrarFalha(ra, ip);

        assertTrue(msgBloqueio.contains("Bloqueado por 30 segundos"),
                "5a falha deve aplicar lockout base de 30s: " + msgBloqueio);
        assertFalse(limitador.permitirTentativa(ra, ip),
                "Estado BLOQUEADO_N1 deve recusar novas tentativas");
        long restantes = limitador.segundosRestantesBloqueio(ra);
        assertTrue(restantes >= 28 && restantes <= 31,
                "Segundos restantes devem estar na faixa do lockout de 30s, obtido: " + restantes);
    }

    @Test
    @Order(3)
    @DisplayName("Seq 3 [BLOQUEADO_N1 -> BLOQUEADO_N2 -> BLOQUEADO_N3]: Escalonamento progressivo (5min e 30min)")
    void seq3EscalonamentoProgressivoNiveis2e3() {
        String ra = "25015323";
        String ip = "10.0.0.33";

        String ultimaMsg = "";
        // Acumula ate a 15a falha (3x maxTentativas = 10x lockout = 5 minutos)
        for (int i = 1; i <= 15; i++) {
            ultimaMsg = limitador.registrarFalha(ra, ip);
        }
        assertTrue(ultimaMsg.contains("Bloqueado por 5 minutos"),
                "15a falha deve escalonar para BLOQUEADO_N2 (5 min): " + ultimaMsg);
        assertFalse(limitador.permitirTentativa(ra, ip));
        assertTrue(limitador.segundosRestantesBloqueio(ra) >= 295,
                "Lockout nivel 2 deve ser ~300s");

        // Acumula ate a 30a falha (6x maxTentativas = 60x lockout = 30 minutos)
        for (int i = 16; i <= 30; i++) {
            ultimaMsg = limitador.registrarFalha(ra, ip);
        }
        assertTrue(ultimaMsg.contains("Bloqueado por 30 minutos"),
                "30a falha deve escalonar para BLOQUEADO_N3 (30 min): " + ultimaMsg);
        assertFalse(limitador.permitirTentativa(ra, ip));
        assertTrue(limitador.segundosRestantesBloqueio(ra) >= 1795,
                "Lockout nivel 3 deve ser ~1800s");
    }

    @Test
    @Order(4)
    @DisplayName("Seq 4 [NORMALIZACAO & ISOLAMENTO]: Case-insensitivity, trim, null/vazio e isolamento entre contas")
    void seq4NormalizacaoChavesEComponentesIsolados() {
        String ip = "172.16.10.5";

        limitador.registrarFalha("  Aluno.Teste@PUC.edu  ", ip);
        limitador.registrarFalha("aluno.teste@puc.edu", ip);
        limitador.registrarFalha("ALUNO.TESTE@PUC.EDU", ip);
        limitador.registrarFalha("aluno.teste@puc.edu ", ip);
        String quinta = limitador.registrarFalha(" aluno.teste@puc.edu", ip);

        assertTrue(quinta.contains("Bloqueado por 30 segundos"),
                "Normalizacao deve unificar variacoes de caixa e espacos na mesma chave");
        assertFalse(limitador.permitirTentativa("ALUNO.TESTE@PUC.EDU", "172.16.10.99"),
                "Bloqueio por usuario deve valer mesmo mudando o IP de origem");

        assertTrue(limitador.permitirTentativa("outro.usuario@puc.edu", "172.16.10.99"),
                "Outro usuario nao deve ser afetado pelo lockout de outra identidade");

        assertDoesNotThrow(() -> {
            limitador.registrarFalha(null, null);
            limitador.registrarFalha("   ", "");
            limitador.permitirTentativa(null, "");
            limitador.segundosRestantesBloqueio(null);
        });
    }

    @Test
    @Order(5)
    @DisplayName("Seq 5 [DETECCAO DE ANOMALIA #2]: Evidencia ausencia de lockout na dimensao IP em password spraying")
    void seq5EvidenciaAnomaliaPasswordSprayingPorIp() {
        String ipAtacante = "203.0.113.50";

        for (int i = 1; i <= 6; i++) {
            limitador.registrarFalha("vitima_" + i + "@puc.edu", ipAtacante);
        }

        // ANOMALIA DOCUMENTADA (LimitadorTentativas.java linhas 87-106):
        // Embora regIp.registrarFalha() incremente o contador do IP, aplicarBloqueio()
        // nunca e invocado em regIp — logo uma 7a conta vinda do mesmo IP ainda e permitida!
        boolean permitidoSetimaContaMesmoIp = limitador.permitirTentativa("vitima_7@puc.edu", ipAtacante);
        assertTrue(permitidoSetimaContaMesmoIp,
                "Evidencia empirica da Anomalia #2: regIp contabiliza falhas mas nao aplica lockout");
    }
}
