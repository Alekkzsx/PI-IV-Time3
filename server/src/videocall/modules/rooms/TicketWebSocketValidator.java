// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.modules.rooms;

/**
 * Consome atomicamente no MongoDB (single-use) o ticket WebSocket antes do upgrade RFC 6455.
 */
public final class TicketWebSocketValidator {
    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private TicketWebSocketValidator() {}

    /**
     * Portao de autorizacao do upgrade WebSocket: valida o formato do ticket
     * (43 chars Base64URL = 32 bytes aleatorios) e da sala, e CONSOME o ticket
     * atomicamente no Mongo (findOneAndDelete). Uso unico: replay ou corrida
     * com o mesmo ticket falha. Qualquer erro = false (fail-closed).
     */
    public static boolean consume(String ticket, String roomCode) {
        if (ticket == null || !ticket.matches("^[A-Za-z0-9_-]{43}$")) {
            return false;
        }
        if (roomCode == null || !roomCode.matches("[A-Za-z0-9._-]{1,60}")) {
            return false;
        }
        try {
            // Prefere a instancia ja conectada; so cria uma nova se o banco ainda nao subiu.
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
