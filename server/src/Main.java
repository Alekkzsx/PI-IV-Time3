// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Atualizado com modulo completo de autenticacao institucional

import auth.AdminUsersHandler;
import auth.AuthSessionHandler;
import auth.ChangePasswordHandler;
import auth.EmailDiagnosticHandler;
import auth.LoginHandler;
import auth.LogoutHandler;
import auth.ProfileAccountHandler;
import auth.RecoveryHandler;
import auth.RefreshTokenHandler;
import auth.RepositorioUsuarios;
import auth.TwoFactorHandler;
import bridge.ClientePonteAcademica;
import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import core.ServidorHttpNativo;
import utils.ConfigEnv;
import utils.Json;
import videocall.RepositorioVideoCall;
import videocall.VideoCallAttendanceHandler;
import videocall.VideoCallInteractionHandler;
import videocall.VideoCallMongoHandler;
import videocall.VideoCallRoomHandler;
import videocall.VideoCallSignalingHandler;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Ponto de entrada central do servidor HTTP nativo da plataforma AGMRM.
 * Orquestra e registra os modulos de autenticacao JWT e de videochamada.
 *
 * Responsabilidades do servidor Java (porta 8080):
 * 1. Autenticacao completa de usuarios (login, logout, 2FA, recuperacao de senha)
 * 2. Gerenciamento de videochamadas (salas, sinalizacao WebRTC, chat, presenca)
 *
 * Modulo de Autenticacao (100% nativo, sem dependencias externas):
 * - POST /api/auth/login          - Login com PBKDF2, rate limiting e 2FA
 * - POST /api/auth/logout         - Revoga token (blacklist em memoria)
 * - POST /api/auth/refresh        - Renova par de tokens (rotacao automatica)
 * - POST /api/auth/verify-two-factor - Verifica 2FA OTP
 * - POST /api/auth/send-recovery-otp - Envia OTP de recuperacao
 * - POST /api/auth/verify-recovery-otp - Valida OTP de recuperacao
 * - POST /api/auth/reset-password - Redefine senha via recovery token
 * - POST /api/auth/change-password - Altera senha (autenticado)
 * - GET  /api/auth/session        - Valida sessao ativa
 */
public class Main {
    private static final int PORTA_PADRAO = 8080;

    public static void main(String[] args) {
        int porta = ConfigEnv.obterInteiro("SERVER_PORT", PORTA_PADRAO);
        if (args != null && args.length > 0) {
            try {
                porta = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                System.out.println("[CONFIG] Porta informada invalida. Utilizando porta: " + porta);
            }
        }

        // =========================================================================
        // 1. MODULO DE AUTENTICACAO, CONTA E USUARIOS ADMIN (MONGODB)
        // =========================================================================
        final RepositorioUsuarios repositorio = RepositorioUsuarios.getInstance();
        final RepositorioVideoCall repositorioVideoCall = RepositorioVideoCall.getInstance();
        final ClientePonteAcademica ponte = new ClientePonteAcademica();

        // Shutdown hook para encerrar pool de emails e conexoes do MongoDB
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                System.out.println("[SHUTDOWN] Encerrando pool de threads SMTP...");
                auth.SmtpCliente.encerrar();
                System.out.println("[SHUTDOWN] Fechando conexao com MongoDB...");
                repositorio.encerrarDefinitivo();
                System.out.println("[SHUTDOWN] Servidor finalizado com sucesso.");
            }
        }, "shutdown-hook"));

        ServidorHttpNativo servidor = new ServidorHttpNativo(porta);

        // Healthcheck explicito do contexto Identidade + Videochamada
        servidor.registrarRota("/health", new ManipuladorHttp() {
            @Override
            public void handle(RequisicaoHttp req, RespostaHttp resp) throws IOException {
                HttpUtils.aplicarHeadersCors(req, resp);
                if ("OPTIONS".equalsIgnoreCase(req.getMetodo())) {
                    resp.enviar(204, "");
                    return;
                }
                RepositorioUsuarios.EstadoSaudeBanco saude = repositorio.verificarSaudeBanco();
                Map<String, Object> payload = new LinkedHashMap<String, Object>();
                payload.put("status", "ok");
                payload.put("service", "agmrm-identity-videocall");
                payload.put("database", saude.disponivel ? "connected" : "unreachable");
                if (!saude.disponivel) {
                    payload.put("databaseCode", saude.codigo);
                    payload.put("databaseDetail", saude.detalhe);
                }
                resp.enviarJson(200, Json.escrever(payload));
            }
        });

        servidor.registrarRota("/health/ready", new ManipuladorHttp() {
            @Override
            public void handle(RequisicaoHttp req, RespostaHttp resp) throws IOException {
                HttpUtils.aplicarHeadersCors(req, resp);
                if ("OPTIONS".equalsIgnoreCase(req.getMetodo())) {
                    resp.enviar(204, "");
                    return;
                }
                RepositorioUsuarios.EstadoSaudeBanco saude = repositorio.verificarSaudeBanco();
                Map<String, Object> payload = new LinkedHashMap<String, Object>();
                payload.put("status", saude.disponivel ? "ready" : "degraded");
                payload.put("service", "agmrm-identity-videocall");
                payload.put("database", saude.disponivel ? "connected" : "unreachable");
                if (!saude.disponivel) {
                    payload.put("code", saude.codigo);
                    payload.put("message", saude.detalhe);
                }
                resp.enviarJson(saude.disponivel ? 200 : 503, Json.escrever(payload));
            }
        });

        // Login e sessao
        servidor.registrarRota("/api/auth/login", new LoginHandler(repositorio));
        servidor.registrarRota("/api/auth/logout", new LogoutHandler(repositorio));
        AuthSessionHandler sessionHandler = new AuthSessionHandler(repositorio);
        servidor.registrarRota("/api/auth/session", sessionHandler);
        servidor.registrarRota("/api/auth/me", sessionHandler);
        servidor.registrarRota("/api/auth/refresh", new RefreshTokenHandler(repositorio));

        // Conta, Perfil, Sessoes Ativas, 2FA Settings, Backup Codes, Logs e LGPD
        ProfileAccountHandler accountHandler = new ProfileAccountHandler(repositorio, ponte);
        servidor.registrarRota("/api/auth/profile", accountHandler);
        servidor.registrarRota("/api/auth/sessions", accountHandler);
        servidor.registrarRota("/api/auth/logout-others", accountHandler);
        servidor.registrarRota("/api/auth/two-factor", accountHandler);
        servidor.registrarRota("/api/auth/backup-codes", accountHandler);
        servidor.registrarRota("/api/auth/security-logs", accountHandler);
        servidor.registrarRota("/api/auth/lgpd-export", accountHandler);

        // 2FA (Two-Factor Authentication)
        servidor.registrarRota("/api/auth/verify-two-factor", new TwoFactorHandler(repositorio));

        // Recuperacao de senha
        RecoveryHandler recoveryHandler = new RecoveryHandler(repositorio);
        servidor.registrarRota("/api/auth/send-recovery-otp", recoveryHandler);
        servidor.registrarRota("/api/auth/verify-recovery-otp", recoveryHandler);
        servidor.registrarRota("/api/auth/reset-password", recoveryHandler);

        // Alteracao de senha (autenticado)
        servidor.registrarRota("/api/auth/change-password", new ChangePasswordHandler(repositorio));

        // Diagnostico de email (apenas admin)
        servidor.registrarRota("/api/auth/email-diagnostic", new EmailDiagnosticHandler());

        // Administracao de contas e usuarios (apenas admin)
        AdminUsersHandler adminUsersHandler = new AdminUsersHandler(repositorio, ponte);
        servidor.registrarRota("/api/admin/users", adminUsersHandler);
        servidor.registrarRota("/api/admin/teachers", adminUsersHandler);

        // =========================================================================
        // 2. MODULO DE VIDEOCHAMADA PERSISTIDA & SINALIZACAO WEBRTC
        // =========================================================================
        VideoCallMongoHandler videoCallMongoHandler = new VideoCallMongoHandler(repositorio, repositorioVideoCall, ponte);
        servidor.registrarRota("/api/video-call", videoCallMongoHandler);

        // Rotas legadas/compatibilidade (sinalizacao HTTP opcional + alias de healthcheck)
        VideoCallRoomHandler roomHandler = new VideoCallRoomHandler();
        servidor.registrarRota("/api/videocall/rooms", roomHandler);
        servidor.registrarRota("/api/videocall/open", roomHandler);
        servidor.registrarRota("/api/videocall/close", roomHandler);

        VideoCallSignalingHandler signalingHandler = new VideoCallSignalingHandler();
        servidor.registrarRota("/api/videocall/join", signalingHandler);
        servidor.registrarRota("/api/videocall/leave", signalingHandler);
        servidor.registrarRota("/api/videocall/signal", signalingHandler);

        VideoCallInteractionHandler interactionHandler = new VideoCallInteractionHandler();
        servidor.registrarRota("/api/videocall/hand-raise", interactionHandler);
        servidor.registrarRota("/api/videocall/chat", interactionHandler);

        servidor.registrarRota("/api/videocall/attendance", new VideoCallAttendanceHandler());

        try {
            servidor.iniciar();
        } catch (IOException e) {
            System.err.println("[FALHA FATAL] Nao foi possivel iniciar o servidor na porta " + porta + ": " + e.getMessage());
            System.exit(1);
        }
    }
}
