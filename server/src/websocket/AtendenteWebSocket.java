// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package websocket;

import core.RequisicaoHttp;

import java.io.IOException;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

// Converte uma requisicao HTTP de upgrade em uma conexao WebSocket.
/**
 * Converte uma requisicao HTTP de upgrade em uma conexao WebSocket.
 * Ponte entre o mundo HTTP (ServidorHttpNativo) e o mundo WebSocket (ConexaoWebSocket):
 * valida o handshake, responde 101 e inicia a thread dedicada da conexao.
 */
public final class AtendenteWebSocket {
    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private AtendenteWebSocket() {}

    /**
     * Assume o socket HTTP para WebSocket.
     * Handshake invalido: escreve um 400 cru (RespostaHttp nao e usado porque o socket
     * esta em transicao de protocolo) e devolve false - o servidor continua dono e fecha.
     * Handshake valido: envia 101, starta a ConexaoWebSocket e devolve true - a posse
     * do socket passa para a nova thread e o servidor nao deve mais toca-lo.
     *
     * @param recurso codigo da sala (identifica a conexao no hub)
     * @param ouvinte callbacks de eventos (SalaVideoHub)
     * @return true se o socket foi assumido pela conexao WebSocket
     */
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