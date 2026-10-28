// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import academic.BoletimHandler;
import academic.PresencaHandler;
import academic.TarefasHandler;
import academic.TesteTiposHandler;
import auth.AuthRecoveryHandler;
import core.ServidorHttpNativo;
import videocall.VideoCallAttendanceHandler;
import videocall.VideoCallInteractionHandler;
import videocall.VideoCallRoomHandler;
import videocall.VideoCallSignalingHandler;

import java.io.IOException;

/**
 * Ponto de entrada central do servidor HTTP nativo da plataforma AGMRM.
 * Orquestra e registra os modulos academicos, videochamada e autenticacao institucional.
 */
public class Main {
    private static final int PORTA_PADRAO = 8080;

    public static void main(String[] args) {
        int porta = PORTA_PADRAO;
        if (args != null && args.length > 0) {
            try {
                porta = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                System.out.println("[CONFIG] Porta informada invalida. Utilizando porta padrao: " + PORTA_PADRAO);
            }
        }

        ServidorHttpNativo servidor = new ServidorHttpNativo(porta);

        // =========================================================================
        // 1. MODULO ACADEMICO (Boletim, Frequencia, Tarefas e Tipos)
        // =========================================================================
        servidor.registrarRota("/api/teste-tipos", new TesteTiposHandler());
        servidor.registrarRota("/api/presenca", new PresencaHandler());
        servidor.registrarRota("/api/tarefas/calcular-nota", new TarefasHandler());
        servidor.registrarRota("/api/notas/boletim", new BoletimHandler());

        // =========================================================================
        // 2. MODULO DE VIDEOCHAMADA & SINALIZACAO WEBRTC
        // =========================================================================
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

        // =========================================================================
        // 3. MODULO DE AUTENTICACAO & RECUPERACAO REAL VIA E-MAIL (OTP)
        // =========================================================================
        AuthRecoveryHandler recoveryHandler = new AuthRecoveryHandler();
        servidor.registrarRota("/api/auth/send-recovery-otp", recoveryHandler);
        servidor.registrarRota("/api/auth/verify-recovery-otp", recoveryHandler);

        try {
            servidor.iniciar();
        } catch (IOException e) {
            System.err.println("[FALHA FATAL] Nao foi possivel iniciar o servidor na porta " + porta + ": " + e.getMessage());
            System.exit(1);
        }
    }
}

