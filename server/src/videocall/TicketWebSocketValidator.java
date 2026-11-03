// Desenvolvido por Marcelo Zarpelon

package videocall;

import utils.ConfigEnv;

import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

// Consome na API autenticada a permissao de uso unico antes do upgrade WebSocket.
public final class TicketWebSocketValidator {
    private static final int TIMEOUT_MS = 2500;

    private TicketWebSocketValidator() {}

    public static boolean consume(String ticket, String roomCode) {
        if (ticket == null || !ticket.matches("[A-Za-z0-9_-]{40,64}")) return false;
        if (roomCode == null || !roomCode.matches("[A-Za-z0-9._-]{1,60}")) return false;

        HttpURLConnection connection = null;
        try {
            String baseUrl = ConfigEnv.obter("AUTH_API_BASE_URL", "http://127.0.0.1:3001");
            while (baseUrl.endsWith("/")) baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
            String query = "ticket=" + URLEncoder.encode(ticket, "UTF-8")
                    + "&roomCode=" + URLEncoder.encode(roomCode, "UTF-8");
            URL url = new URL(baseUrl + "/api/video-call/rooms/consume-ticket?" + query);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(TIMEOUT_MS);
            connection.setReadTimeout(TIMEOUT_MS);
            return connection.getResponseCode() == HttpURLConnection.HTTP_NO_CONTENT;
        } catch (Exception e) {
            return false;
        } finally {
            if (connection != null) connection.disconnect();
        }
    }
}
