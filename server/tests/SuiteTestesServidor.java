// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
// Executor unificado das 17 suites de teste nativas em Java SE puro (sem JUnit)

import auth.HandlerLifecycleTeste;
import auth.JwtAuthValidatorTeste;
import auth.LimitadorTentativasTeste;
import auth.OtpServiceTeste;
import auth.RecoveryHandlerTeste;
import auth.ResilientNetworkTeste;
import auth.RevogacaoTokensTeste;
import auth.SenhaHasherTeste;
import auth.SmtpClienteTeste;
import core.ArquiteturaAbstrataTeste;
import core.HttpUtilsCorsTeste;
import utils.ConfigEnvTeste;
import utils.JsonTeste;
import videocall.hub.HubTeste;
import videocall.hub.RegistradorChatTeste;
import websocket.HandshakeTeste;
import websocket.QuadroTeste;

/**
 * Runner unificado das 17 suites nativas (sem JUnit): executa cada executar() em ordem,
 * soma as falhas e define o exit code do processo (0 = tudo passou, 1 = alguma falha).
 * E o portao de qualidade do servidor: roda offline, sem Mongo/rede externos.
 */
public class SuiteTestesServidor {
    /** Executa as 17 suites em sequencia; qualquer falha encerra com System.exit(1). */
    public static void main(String[] args) throws Exception {
        int totalFalhas = 0;

        System.out.println("=== 1/17 ConfigEnv Master .env ===");
        totalFalhas += ConfigEnvTeste.executar();

        System.out.println("\n=== 2/17 Json & JsonSimples ===");
        totalFalhas += JsonTeste.executar();

        System.out.println("\n=== 3/17 WebSocket Handshake (RFC 6455) ===");
        totalFalhas += HandshakeTeste.executar();

        System.out.println("\n=== 4/17 WebSocket Quadros (RFC 6455) ===");
        totalFalhas += QuadroTeste.executar();

        System.out.println("\n=== 5/17 VideoCall RegistradorChat ===");
        totalFalhas += RegistradorChatTeste.executar();

        System.out.println("\n=== 6/17 VideoCall SalaVideoHub Integracao ===");
        totalFalhas += HubTeste.executar();

        System.out.println("\n=== 7/17 Autenticacao JWT HS256 Nativa ===");
        totalFalhas += JwtAuthValidatorTeste.executar();

        System.out.println("\n=== 8/17 SenhaHasher PBKDF2 & BCrypt ===");
        totalFalhas += SenhaHasherTeste.executar();

        System.out.println("\n=== 9/17 RevogacaoTokens (blacklist) ===");
        totalFalhas += RevogacaoTokensTeste.executar();

        System.out.println("\n=== 10/17 LimitadorTentativas (rate limiting) ===");
        totalFalhas += LimitadorTentativasTeste.executar();

        System.out.println("\n=== 11/17 OtpService (2FA e recuperacao) ===");
        totalFalhas += OtpServiceTeste.executar();

        System.out.println("\n=== 12/17 RecoveryHandler (reset token de uso unico) ===");
        totalFalhas += RecoveryHandlerTeste.executar();

        System.out.println("\n=== 13/17 HandlerLifecycle (preservacao do pool DB) ===");
        totalFalhas += HandlerLifecycleTeste.executar();

        System.out.println("\n=== 14/17 HttpUtilsCors (origem unica, porta dinamica e PNA) ===");
        totalFalhas += HttpUtilsCorsTeste.executar();

        System.out.println("\n=== 15/17 ResilientNetwork (DoH fallback e 503 rede bloqueada) ===");
        totalFalhas += ResilientNetworkTeste.executar();

        System.out.println("\n=== 16/17 SmtpCliente (RFC 5321 CRLF, AUTH PLAIN/LOGIN, Webhook e Circuit Breaker) ===");
        totalFalhas += SmtpClienteTeste.executar();

        System.out.println("\n=== 17/17 ArquiteturaAbstrata (Template Method, Excecoes HTTP, Canais/Templates e Utils) ===");
        totalFalhas += ArquiteturaAbstrataTeste.executar();

        System.out.println("\n==========================================");
        if (totalFalhas > 0) {
            System.out.println("[RESULTADO] FALHOU com " + totalFalhas + " erro(s).");
            System.exit(1);
        }
        System.out.println("[RESULTADO] TODAS AS 17 SUITES NATIVAS PASSARAM COM SUCESSO!");
    }
}
