// Desenvolvido por Marcelo Zarpelon

package videocall;

import api.Campo;
import api.Esquema;

// Esquemas das colecoes da video chamada, espelhando MeetingRoom, ChatMessage e RecordingState do frontend.
public final class VideoCallEsquemas {
    private VideoCallEsquemas() {}

    public static final String SALAS = "salas_video";
    public static final String SESSOES = "sessoes_video";
    public static final String MENSAGENS = "mensagens_chat";

    // status: AGENDADA, ATIVA ou ENCERRADA
    public static final Esquema ESQUEMA_SALAS = new Esquema(
            Campo.texto("codigo", true, 60),
            Campo.texto("titulo", true, 160),
            Campo.texto("docenteId", true, 60),
            Campo.texto("cursoId", false, 60),
            Campo.texto("status", true, 20),
            Campo.texto("agendadaPara", false, 40),
            Campo.texto("criadaEm", false, 40));

    // Uma execucao da sala: quem entrou, quando, e onde ficou a gravacao.
    public static final Esquema ESQUEMA_SESSOES = new Esquema(
            Campo.texto("salaId", true, 60),
            Campo.texto("iniciadaEm", true, 40),
            Campo.texto("encerradaEm", false, 40),
            Campo.lista("participantes", false, 200),
            Campo.texto("gravacao", false, 300));

    public static final Esquema ESQUEMA_MENSAGENS = new Esquema(
            Campo.texto("salaId", true, 60),
            Campo.texto("remetenteId", true, 80),
            Campo.texto("remetente", false, 120),
            Campo.texto("texto", true, 2000),
            Campo.inteiro("enviadaEm", true));
}
