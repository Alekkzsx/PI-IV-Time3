// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package utils;

import core.RequisicaoHttp;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/**
 * Funcoes reutilizaveis de rede, streams HTTP, URLs e extracao de IP de clientes.
 * Elimina duplicacao entre Ponte Academica, Cliente SMTP, DNS DoH e Handlers HTTP.
 */
public final class RedeUtils {
    private RedeUtils() {}

    /**
     * Le todo o conteudo de um InputStream em UTF-8 fechando o stream ao finalizar.
     */
    public static String lerStreamUtf8(InputStream stream) throws IOException {
        if (stream == null) {
            return "";
        }
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        byte[] chunk = new byte[4096];
        int lidos;
        try {
            while ((lidos = stream.read(chunk)) != -1) {
                buffer.write(chunk, 0, lidos);
            }
        } finally {
            try {
                stream.close();
            } catch (IOException ignored) { }
        }
        return new String(buffer.toByteArray(), StandardCharsets.UTF_8);
    }

    /**
     * Codifica um parametro para query string ou segmento de URL em UTF-8.
     */
    public static String urlEncode(String valor) {
        try {
            return URLEncoder.encode(valor != null ? valor : "", "UTF-8");
        } catch (UnsupportedEncodingException e) {
            return valor != null ? valor : "";
        }
    }

    /**
     * Remove barras finais repetidas de uma URL ou origem CORS.
     */
    public static String limparBarraFinal(String valor) {
        if (valor == null) {
            return "";
        }
        String limpo = valor.trim();
        while (limpo.endsWith("/")) {
            limpo = limpo.substring(0, limpo.length() - 1);
        }
        return limpo;
    }

    /**
     * Verifica se o host representa loopback local (127.0.0.1, localhost, ::1).
     */
    public static boolean isLoopbackHost(String host) {
        if (host == null) {
            return false;
        }
        String clean = host.trim().toLowerCase(Locale.ROOT);
        return "127.0.0.1".equals(clean)
                || "localhost".equals(clean)
                || "::1".equals(clean)
                || "[::1]".equals(clean);
    }

    /**
     * Extrai o IP real do cliente respeitando X-Forwarded-For e X-Real-IP.
     */
    public static String extrairIpCliente(RequisicaoHttp requisicao, String fallback) {
        if (requisicao == null) {
            return fallback;
        }
        String forwarded = requisicao.getCabecalho("x-forwarded-for");
        if (forwarded != null && !forwarded.trim().isEmpty()) {
            int virgula = forwarded.indexOf(',');
            return virgula > 0 ? forwarded.substring(0, virgula).trim() : forwarded.trim();
        }
        String realIp = requisicao.getCabecalho("x-real-ip");
        if (realIp != null && !realIp.trim().isEmpty()) {
            return realIp.trim();
        }
        return fallback;
    }
}
