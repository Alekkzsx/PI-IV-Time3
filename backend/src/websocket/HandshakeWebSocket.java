// Desenvolvido por Marcelo Zarpelon

package websocket;

import server.RequisicaoHttp;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

// Handshake de abertura do WebSocket (RFC 6455, secao 4).
public final class HandshakeWebSocket {
    private static final String GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

    private HandshakeWebSocket() {}

    // Verifica se a requisicao pede a troca de protocolo para WebSocket.
    public static boolean pedeUpgrade(RequisicaoHttp req) {
        String upgrade = req.getCabecalho("Upgrade");
        return upgrade != null && upgrade.equalsIgnoreCase("websocket");
    }

    // Valida os cabecalhos obrigatorios e devolve a chave do cliente.
    public static String validar(RequisicaoHttp req) {
        if (!req.getMetodo().equals("GET")) throw new IllegalArgumentException("Handshake exige GET");
        String conexao = req.getCabecalho("Connection");
        if (conexao == null || !conexao.toLowerCase().contains("upgrade")) throw new IllegalArgumentException("Cabecalho Connection invalido");
        if (!"13".equals(req.getCabecalho("Sec-WebSocket-Version"))) throw new IllegalArgumentException("Versao WebSocket deve ser 13");
        String chave = req.getCabecalho("Sec-WebSocket-Key");
        if (chave == null) throw new IllegalArgumentException("Sec-WebSocket-Key ausente");
        try {
            if (Base64.getDecoder().decode(chave).length != 16) throw new IllegalArgumentException("Sec-WebSocket-Key invalida");
        } catch (IllegalArgumentException e) { throw new IllegalArgumentException("Sec-WebSocket-Key invalida"); }
        return chave;
    }

    // Sec-WebSocket-Accept = Base64(SHA-1(chave + GUID)).
    public static String calcularAccept(String chave) {
        try {
            MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
            return Base64.getEncoder().encodeToString(sha1.digest((chave + GUID).getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException e) { throw new IllegalStateException("SHA-1 indisponivel", e); }
    }

    public static void responder(OutputStream saida, String chave) throws IOException {
        String resposta = "HTTP/1.1 101 Switching Protocols\r\n"
                + "Upgrade: websocket\r\n"
                + "Connection: Upgrade\r\n"
                + "Sec-WebSocket-Accept: " + calcularAccept(chave) + "\r\n\r\n";
        saida.write(resposta.getBytes(StandardCharsets.US_ASCII));
        saida.flush();
    }
}
