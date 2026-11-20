// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package websocket;

import core.RequisicaoHttp;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

// Handshake de abertura do WebSocket (RFC 6455, secao 4).
/**
 * Handshake de abertura do WebSocket (RFC 6455, secao 4).
 * O cliente envia um GET com Upgrade: websocket e uma Sec-WebSocket-Key aleatoria;
 * o servidor prova que entende o protocolo devolvendo 101 com Sec-WebSocket-Accept =
 * Base64(SHA-1(key + GUID magico)). Apos o 101, o socket deixa de falar HTTP.
 */
public final class HandshakeWebSocket {
    // GUID fixo definido pela RFC 6455 (secao 1.3): concatenado a key antes do SHA-1.
    private static final String GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private HandshakeWebSocket() {}

    /** Detecao barata do pedido de upgrade (nao valida o handshake completo; isso e validar()). */
    public static boolean pedeUpgrade(RequisicaoHttp req) {
        String upgrade = req.getCabecalho("Upgrade");
        return upgrade != null && upgrade.equalsIgnoreCase("websocket");
    }

    /**
     * Valida os requisitos obrigatorios do handshake de abertura:
     * GET + Connection contendo "upgrade" + versao 13 + key Base64 de exatamente 16 bytes.
     *
     * @return a Sec-WebSocket-Key validada (necessaria para calcular o Accept)
     * @throws IllegalArgumentException se qualquer requisito da RFC falhar (vira HTTP 400)
     */
    public static String validar(RequisicaoHttp req) {
        if (!req.getMetodo().equals("GET")) throw new IllegalArgumentException("Handshake exige GET");
        String conexao = req.getCabecalho("Connection");
        // Connection pode ser lista ("keep-alive, Upgrade"): busca por substring, nao igualdade.
        if (conexao == null || !conexao.toLowerCase().contains("upgrade")) throw new IllegalArgumentException("Cabecalho Connection invalido");
        // Versao 13 e a unica do protocolo final RFC 6455 (rascunhos hixie/hybi sao rejeitados).
        if (!"13".equals(req.getCabecalho("Sec-WebSocket-Version"))) throw new IllegalArgumentException("Versao WebSocket deve ser 13");
        String chave = req.getCabecalho("Sec-WebSocket-Key");
        if (chave == null) throw new IllegalArgumentException("Sec-WebSocket-Key ausente");
        try {
            // A RFC exige 16 bytes aleatorios codificados em Base64 (24 chars com padding).
            if (Base64.getDecoder().decode(chave).length != 16) throw new IllegalArgumentException("Sec-WebSocket-Key invalida");
        } catch (IllegalArgumentException e) { throw new IllegalArgumentException("Sec-WebSocket-Key invalida"); }
        return chave;
    }

    /**
     * Calcula Sec-WebSocket-Accept = Base64(SHA-1(key + GUID)).
     * SHA-1 aqui nao e criptografia de seguranca: e apenas a prova de entendimento do
     * protocolo exigida pela RFC (evita upgrades acidentais por caches/proxies).
     */
    public static String calcularAccept(String chave) {
        try {
            MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
            return Base64.getEncoder().encodeToString(sha1.digest((chave + GUID).getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException e) { throw new IllegalStateException("SHA-1 indisponivel", e); }
    }

    /** Escreve a resposta 101 Switching Protocols crua no socket (sem corpo; fim do HTTP nesta conexao). */
    public static void responder(OutputStream saida, String chave) throws IOException {
        String resposta = "HTTP/1.1 101 Switching Protocols\r\n"
                + "Upgrade: websocket\r\n"
                + "Connection: Upgrade\r\n"
                + "Sec-WebSocket-Accept: " + calcularAccept(chave) + "\r\n\r\n";
        saida.write(resposta.getBytes(StandardCharsets.US_ASCII));
        saida.flush();
    }
}