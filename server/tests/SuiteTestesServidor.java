// Desenvolvido por Alex Gabriel Soares Sousa, Marcelo Zarpelon e Guilherme Henrique Moreira

import auth.JwtAuthValidatorTeste;
import utils.JsonTeste;
import videocall.hub.HubTeste;
import videocall.hub.RegistradorChatTeste;
import websocket.HandshakeTeste;
import websocket.QuadroTeste;

/**
 * Executor unificado dos testes nativos em Java SE puro (sem JUnit ou bibliotecas externas)
 * do servidor AGMRM (JSON, WebSocket RFC 6455, VideoCall Hub, RegistradorChat e JWT HS256).
 */
public class SuiteTestesServidor {
    public static void main(String[] args) throws Exception {
        int totalFalhas = 0;

        System.out.println("=== 1/6 Json & JsonSimples ===");
        totalFalhas += JsonTeste.executar();

        System.out.println("=== 2/6 WebSocket Handshake (RFC 6455) ===");
        totalFalhas += HandshakeTeste.executar();

        System.out.println("=== 3/6 WebSocket Quadros (RFC 6455) ===");
        totalFalhas += QuadroTeste.executar();

        System.out.println("=== 4/6 VideoCall RegistradorChat ===");
        totalFalhas += RegistradorChatTeste.executar();

        System.out.println("=== 5/6 VideoCall SalaVideoHub Integracao ===");
        totalFalhas += HubTeste.executar();

        System.out.println("=== 6/6 Autenticacao JWT HS256 Nativa ===");
        totalFalhas += JwtAuthValidatorTeste.executar();

        System.out.println("==========================================");
        if (totalFalhas > 0) {
            System.out.println("[RESULTADO] FALHOU com " + totalFalhas + " erro(s).");
            System.exit(1);
        }
        System.out.println("[RESULTADO] TODAS AS 6 SUITES NATIVAS PASSARAM COM SUCESSO!");
    }
}

