// Desenvolvido por Marcelo Zarpelon

package videocall;

import api.Campo;
import api.Esquema;

// Esquemas das colecoes da video chamada (prefixo video_), com campos em ingles como o restante do banco.
// classCode referencia academic_classes e professorIdentity referencia o login do professor.
public final class VideoCallEsquemas {
    private VideoCallEsquemas() {}

    public static final String SALAS = "video_rooms";
    public static final String SESSOES = "video_call_sessions";
    public static final String MENSAGENS = "video_chat_messages";

    // status: SCHEDULED, ACTIVE ou ENDED
    public static final Esquema ESQUEMA_SALAS = new Esquema(
            Campo.texto("code", true, 60),
            Campo.texto("title", true, 160),
            Campo.texto("professorIdentity", true, 60),
            Campo.texto("classCode", false, 60),
            Campo.texto("status", true, 20),
            Campo.texto("scheduledFor", false, 40),
            Campo.texto("createdAt", false, 40));

    // Uma execucao da sala: quem entrou, quando, e onde ficou a gravacao.
    public static final Esquema ESQUEMA_SESSOES = new Esquema(
            Campo.texto("roomId", true, 60),
            Campo.texto("startedAt", true, 40),
            Campo.texto("endedAt", false, 40),
            Campo.lista("participants", false, 200),
            Campo.texto("recordingPath", false, 300));

    public static final Esquema ESQUEMA_MENSAGENS = new Esquema(
            Campo.texto("roomId", true, 60),
            Campo.texto("senderId", true, 80),
            Campo.texto("senderName", false, 120),
            Campo.texto("text", true, 2000),
            Campo.inteiro("sentAt", true));
}
