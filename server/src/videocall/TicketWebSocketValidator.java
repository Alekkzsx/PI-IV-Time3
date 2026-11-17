// Desenvolvido por Marcelo Zarpelon

package videocall;

// Consome localmente no MongoDB (single-use) o ticket WebSocket antes do upgrade.
public final class TicketWebSocketValidator {
    private TicketWebSocketValidator() {}

    public static boolean consume(String ticket, String roomCode) {
        if (ticket == null || !ticket.matches("^[A-Za-z0-9_-]{43}$")) return false;
        if (roomCode == null || !roomCode.matches("[A-Za-z0-9._-]{1,60}")) return false;

        try {
            RepositorioVideoCall repo = RepositorioVideoCall.getInstanciaSeBancoAtivo();
            if (repo == null) {
                repo = RepositorioVideoCall.getInstance();
            }
            return repo.consumirTicketWebSocket(ticket, roomCode);
        } catch (Exception e) {
            return false;
        }
    }
}
