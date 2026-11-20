// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package websocket;

// Teste sem bibliotecas do calculo do handshake com o exemplo da RFC 6455.
/**
 * Suite do handshake WebSocket: confere o Sec-WebSocket-Accept contra o VETOR OFICIAL
 * da RFC 6455 (secao 1.3) - se o SHA-1/GUID/Base64 estiverem corretos, o resultado
 * bate byte a byte com o exemplo normativo.
 */
public class HandshakeTeste {

    /** Executa o cenario da suite; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        // Vetor da RFC: key "dGhlIHNhbXBsZSBub25jZQ==" -> accept "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=".
        String accept = HandshakeWebSocket.calcularAccept("dGhlIHNhbXBsZSBub25jZQ==");
        boolean ok = accept.equals("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=");
        System.out.println((ok ? "[OK]    " : "[FALHA] ") + "Sec-WebSocket-Accept do exemplo da RFC: " + accept);
        return ok ? 0 : 1;
    }

    /** Runner isolado: exit 1 se houver falha. */
    public static void main(String[] args) {
        if (executar() > 0) System.exit(1);
    }
}

