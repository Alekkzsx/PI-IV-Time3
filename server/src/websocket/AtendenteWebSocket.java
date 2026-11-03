// Desenvolvido por Marcelo Zarpelon

package websocket;

import core.RequisicaoHttp;

import java.io.IOException;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

// Converte uma requisicao HTTP de upgrade em uma conexao WebSocket.
public final class AtendenteWebSocket {
    private AtendenteWebSocket() {}

    public static boolean assumir(Socket socket, RequisicaoHttp req, String recurso, OuvinteWebSocket ouvinte) throws IOException {
        String chave;
        try {
            chave = HandshakeWebSocket.validar(req);
        } catch (IllegalArgumentException e) {
            byte[] corpo = ("Handshake invalido: " + e.getMessage()).getBytes(StandardCharsets.UTF_8);
            socket.getOutputStream().write(("HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain; charset=utf-8\r\n"
                    + "Content-Length: " + corpo.length + "\r\nConnection: close\r\n\r\n").getBytes(StandardCharsets.US_ASCII));
            socket.getOutputStream().write(corpo);
            socket.getOutputStream().flush();
            return false;
        }
        HandshakeWebSocket.responder(socket.getOutputStream(), chave);
        new ConexaoWebSocket(socket, recurso, ouvinte).start();
        return true;
    }
}