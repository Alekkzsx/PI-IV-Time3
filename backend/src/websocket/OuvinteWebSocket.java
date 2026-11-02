// Desenvolvido por Marcelo Zarpelon

package websocket;

// Recebe os eventos de uma conexao WebSocket.
public interface OuvinteWebSocket {
    void aoAbrir(ConexaoWebSocket conexao);

    void aoReceberTexto(ConexaoWebSocket conexao, String texto);

    void aoFechar(ConexaoWebSocket conexao);
}
