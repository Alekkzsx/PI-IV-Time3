// Desenvolvido por Marcelo Zarpelon

package websocket;

// Teste sem bibliotecas do calculo do handshake com o exemplo da RFC 6455.
public class HandshakeTeste {

    public static int executar() {
        String accept = HandshakeWebSocket.calcularAccept("dGhlIHNhbXBsZSBub25jZQ==");
        boolean ok = accept.equals("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=");
        System.out.println((ok ? "[OK]    " : "[FALHA] ") + "Sec-WebSocket-Accept do exemplo da RFC: " + accept);
        return ok ? 0 : 1;
    }

    public static void main(String[] args) {
        if (executar() > 0) System.exit(1);
    }
}

