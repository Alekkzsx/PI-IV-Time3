// Desenvolvido por Alex Gabriel Soares Sousa, Marcelo Zarpelon e Guilherme Henrique Moreira
// Atualizado com suites de teste de autenticacao institucional

import auth.HandlerLifecycleTeste;
import auth.JwtAuthValidatorTeste;
import auth.LimitadorTentativasTeste;
import auth.OtpServiceTeste;
import auth.RecoveryHandlerTeste;
import auth.ResilientNetworkTeste;
import auth.RevogacaoTokensTeste;
import auth.SenhaHasherTeste;
import core.HttpUtilsCorsTeste;
import utils.ConfigEnvTeste;
import utils.JsonTeste;
import videocall.hub.HubTeste;
import videocall.hub.RegistradorChatTeste;
import websocket.HandshakeTeste;
import websocket.QuadroTeste;

/**
 * Executor unificado dos testes nativos em Java SE puro (sem JUnit ou bibliotecas externas)
 * do servidor AGMRM.
 *
 * Suites de teste:
 *  1. ConfigEnv Master .env
 *  2. Json & JsonSimples
 *  3. WebSocket Handshake (RFC 6455)
 *  4. WebSocket Quadros (RFC 6455)
 *  5. VideoCall RegistradorChat
 *  6. VideoCall SalaVideoHub Integracao
 *  7. Autenticacao JWT HS256 Nativa
 *  8. SenhaHasher PBKDF2 (hash de senhas)
 *  9. RevogacaoTokens (blacklist de JWT)
 * 10. LimitadorTentativas (rate limiting anti-forca-bruta)
 * 11. OtpService (2FA e recuperacao de senha)
 */
public class SuiteTestesServidor {
    public static void main(String[] args) throws Exception {
        int totalFalhas = 0;

        System.out.println("=== 1/11 ConfigEnv Master .env ===");
        totalFalhas += ConfigEnvTeste.executar();

        System.out.println("\n=== 2/11 Json & JsonSimples ===");
        totalFalhas += JsonTeste.executar();

        System.out.println("\n=== 3/11 WebSocket Handshake (RFC 6455) ===");
        totalFalhas += HandshakeTeste.executar();

        System.out.println("\n=== 4/11 WebSocket Quadros (RFC 6455) ===");
        totalFalhas += QuadroTeste.executar();

        System.out.println("\n=== 5/11 VideoCall RegistradorChat ===");
        totalFalhas += RegistradorChatTeste.executar();

        System.out.println("\n=== 6/11 VideoCall SalaVideoHub Integracao ===");
        totalFalhas += HubTeste.executar();

        System.out.println("\n=== 7/11 Autenticacao JWT HS256 Nativa ===");
        totalFalhas += JwtAuthValidatorTeste.executar();

        System.out.println("\n=== 8/11 SenhaHasher PBKDF2 (hash de senhas) ===");
        totalFalhas += SenhaHasherTeste.executar();

        System.out.println("\n=== 9/11 RevogacaoTokens (blacklist de JWT) ===");
        totalFalhas += RevogacaoTokensTeste.executar();

        System.out.println("\n=== 10/11 LimitadorTentativas (rate limiting) ===");
        totalFalhas += LimitadorTentativasTeste.executar();

        System.out.println("\n=== 11/13 OtpService (2FA e recuperacao) ===");
        totalFalhas += OtpServiceTeste.executar();

        System.out.println("\n=== 12/13 RecoveryHandler (reset token de uso unico) ===");
        totalFalhas += RecoveryHandlerTeste.executar();

        System.out.println("\n=== 13/15 HandlerLifecycle (preservacao do pool DB) ===");
        totalFalhas += HandlerLifecycleTeste.executar();

        System.out.println("\n=== 14/15 HttpUtilsCors (origem unica, porta dinamica e PNA) ===");
        totalFalhas += HttpUtilsCorsTeste.executar();

        System.out.println("\n=== 15/15 ResilientNetwork (DoH fallback e 503 rede bloqueada) ===");
        totalFalhas += ResilientNetworkTeste.executar();

        System.out.println("\n==========================================");
        if (totalFalhas > 0) {
            System.out.println("[RESULTADO] FALHOU com " + totalFalhas + " erro(s).");
            System.exit(1);
        }
        System.out.println("[RESULTADO] TODAS AS 15 SUITES NATIVAS PASSARAM COM SUCESSO!");
    }
}
