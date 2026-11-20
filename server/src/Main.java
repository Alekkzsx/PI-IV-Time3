// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Ponto de entrada central do servidor HTTP/WebSocket nativo da plataforma AGMRM.

import auth.modules.admin.AdminUsersHandler;
import auth.modules.admin.EmailDiagnosticHandler;
import auth.modules.conta.ChangePasswordHandler;
import auth.modules.conta.ProfileAccountHandler;
import auth.modules.conta.RecoveryHandler;
import auth.modules.email.SmtpCliente;
import auth.modules.login.AuthSessionHandler;
import auth.modules.login.LoginHandler;
import auth.modules.login.LogoutHandler;
import auth.modules.login.RefreshTokenHandler;
import auth.modules.login.TwoFactorHandler;
import auth.modules.persistencia.RepositorioUsuarios;
import bridge.ClientePonteAcademica;
import core.HealthHandler;
import core.MonitorBackendAcademico;
import core.ServidorHttpNativo;
import utils.ConfigEnv;
import videocall.modules.legado.VideoCallAttendanceHandler;
import videocall.modules.legado.VideoCallInteractionHandler;
import videocall.modules.legado.VideoCallRoomHandler;
import videocall.modules.legado.VideoCallSignalingHandler;
import videocall.modules.rooms.RepositorioVideoCall;
import videocall.modules.rooms.VideoCallMongoHandler;

import java.io.IOException;

/**
 * Orquestrador central do servidor nativo Java SE (porta 8080).
 * Organiza o registro de rotas em quatro blocos claros:
 * 1. Saude e prontidao (/health, /health/ready)
 * 2. Autenticacao e autoatendimento (/api/auth/*)
 * 3. Administracao de identidades (/api/admin/users*, /api/admin/teachers)
 * 4. Videochamada persistida e sinalizacao WebRTC (/api/video-call*, /api/videocall*, /ws/video-call/*)
 */
public class Main {
    private static final int PORTA_PADRAO = 8080;

    public static void main(String[] args) {
        int porta = resolverPorta(args);

        final RepositorioUsuarios repositorio = RepositorioUsuarios.getInstance();
        final RepositorioVideoCall repositorioVideoCall = RepositorioVideoCall.getInstance();
        final ClientePonteAcademica ponte = new ClientePonteAcademica();

        MonitorBackendAcademico.ativarSeConfigurado();
        registrarShutdownHook(repositorio);

        ServidorHttpNativo servidor = new ServidorHttpNativo(porta);
        registrarRotasSaude(servidor, repositorio);
        registrarRotasAuth(servidor, repositorio, ponte);
        registrarRotasAdmin(servidor, repositorio, ponte);
        registrarRotasVideoCall(servidor, repositorio, repositorioVideoCall, ponte);

        try {
            servidor.iniciar();
        } catch (IOException e) {
            System.err.println("[FALHA FATAL] Nao foi possivel iniciar o servidor na porta "
                    + porta + ": " + e.getMessage());
            System.exit(1);
        }
    }

    private static int resolverPorta(String[] args) {
        int porta = ConfigEnv.obterInteiro("SERVER_PORT", PORTA_PADRAO);
        if (args != null && args.length > 0) {
            try {
                porta = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                System.out.println("[CONFIG] Porta informada invalida. Utilizando porta: " + porta);
            }
        }
        return porta;
    }

    private static void registrarShutdownHook(final RepositorioUsuarios repositorio) {
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                System.out.println("[SHUTDOWN] Encerrando pool de threads SMTP...");
                SmtpCliente.encerrar();
                System.out.println("[SHUTDOWN] Fechando conexao com MongoDB...");
                repositorio.encerrarDefinitivo();
                System.out.println("[SHUTDOWN] Servidor finalizado com sucesso.");
            }
        }, "shutdown-hook"));
    }

    private static void registrarRotasSaude(ServidorHttpNativo servidor, RepositorioUsuarios repositorio) {
        HealthHandler healthHandler = new HealthHandler(repositorio.getConexao());
        servidor.registrarRota("/health", healthHandler);
        servidor.registrarRota("/health/ready", healthHandler);
    }

    private static void registrarRotasAuth(
            ServidorHttpNativo servidor, RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        // Login, 2FA, sessao e renovacao de tokens
        servidor.registrarRota("/api/auth/login", new LoginHandler(repositorio));
        servidor.registrarRota("/api/auth/logout", new LogoutHandler(repositorio));
        servidor.registrarRota("/api/auth/refresh", new RefreshTokenHandler(repositorio));
        servidor.registrarRota("/api/auth/verify-two-factor", new TwoFactorHandler(repositorio));

        AuthSessionHandler sessionHandler = new AuthSessionHandler(repositorio);
        servidor.registrarRota("/api/auth/session", sessionHandler);
        servidor.registrarRota("/api/auth/me", sessionHandler);

        // Conta, perfil, sessoes ativas, configuracoes 2FA, backup codes, logs e LGPD
        ProfileAccountHandler accountHandler = new ProfileAccountHandler(repositorio, ponte);
        servidor.registrarRota("/api/auth/profile", accountHandler);
        servidor.registrarRota("/api/auth/sessions", accountHandler);
        servidor.registrarRota("/api/auth/logout-others", accountHandler);
        servidor.registrarRota("/api/auth/two-factor", accountHandler);
        servidor.registrarRota("/api/auth/backup-codes", accountHandler);
        servidor.registrarRota("/api/auth/security-logs", accountHandler);
        servidor.registrarRota("/api/auth/lgpd-export", accountHandler);

        // Recuperacao e alteracao de senha
        RecoveryHandler recoveryHandler = new RecoveryHandler(repositorio);
        servidor.registrarRota("/api/auth/send-recovery-otp", recoveryHandler);
        servidor.registrarRota("/api/auth/verify-recovery-otp", recoveryHandler);
        servidor.registrarRota("/api/auth/reset-password", recoveryHandler);
        servidor.registrarRota("/api/auth/change-password", new ChangePasswordHandler(repositorio));
    }

    private static void registrarRotasAdmin(
            ServidorHttpNativo servidor, RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        servidor.registrarRota("/api/auth/email-diagnostic", new EmailDiagnosticHandler(repositorio));

        AdminUsersHandler adminUsersHandler = new AdminUsersHandler(repositorio, ponte);
        servidor.registrarRota("/api/admin/users", adminUsersHandler);
        servidor.registrarRota("/api/admin/teachers", adminUsersHandler);
    }

    private static void registrarRotasVideoCall(
            ServidorHttpNativo servidor,
            RepositorioUsuarios repositorio,
            RepositorioVideoCall repositorioVideoCall,
            ClientePonteAcademica ponte) {
        // API oficial persistida em MongoDB
        servidor.registrarRota("/api/video-call", new VideoCallMongoHandler(repositorio, repositorioVideoCall, ponte));

        // API legada em memoria (compatibilidade HTTP)
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
    }
}
