// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

// Monta a resposta HTTP usando OutputStream nativo com suporte a CORS e JSON.
/**
 * Escritor de resposta HTTP/1.1 sobre o OutputStream do socket.
 * Acumula cabecalhos em memoria e os serializa junto com o corpo em enviar().
 * A flag 'enviada' torna o objeto de uso unico: qualquer segunda tentativa de envio
 * falha, protegendo contra respostas duplicadas no mesmo socket (handler + catch de erro).
 * Cada resposta usa Connection: close (sem keep-alive neste servidor).
 */
public class RespostaHttp {
    private final OutputStream saida;
    private final Map<String, String> cabecalhos = new LinkedHashMap<>();
    private boolean enviada = false;

    /** @param saida stream de saida do socket do cliente (quem fecha o socket e o servidor, nao esta classe). */
    public RespostaHttp(OutputStream saida) { 
        this.saida = saida; 
    }

    /** Define/substitui um cabecalho a ser enviado; sobrepoe valores anteriores do mesmo nome. */
    public void adicionarCabecalho(String nome, String valor) { 
        cabecalhos.put(nome, valor); 
    }

    /** @return true se esta resposta ja foi escrita no socket (impede envio duplo no catch do servidor). */
    public boolean foiEnviada() { 
        return enviada; 
    }

    /**
     * Serializa e escreve a resposta completa: status line, cabecalhos, linha vazia e corpo UTF-8.
     * Content-Length e calculado dos bytes reais (nao dos chars) e 204 nunca leva corpo,
     * conforme a RFC 7230.
     *
     * @param status   codigo HTTP (200, 401, 503...)
     * @param conteudo corpo textual (null vira corpo vazio)
     * @throws IOException se a resposta ja foi enviada ou o socket falhar
     */
    public void enviar(int status, String conteudo) throws IOException {
        if (enviada) throw new IOException("Resposta ja enviada");
        byte[] bytes = conteudo != null ? conteudo.getBytes(StandardCharsets.UTF_8) : new byte[0];
        String descricao;
        switch (status) {
            case 200: descricao = "OK"; break;
            case 201: descricao = "Created"; break;
            case 202: descricao = "Accepted"; break;
            case 204: descricao = "No Content"; break;
            case 400: descricao = "Bad Request"; break;
            case 401: descricao = "Unauthorized"; break;
            case 403: descricao = "Forbidden"; break;
            case 404: descricao = "Not Found"; break;
            case 405: descricao = "Method Not Allowed"; break;
            case 409: descricao = "Conflict"; break;
            case 422: descricao = "Unprocessable Entity"; break;
            case 429: descricao = "Too Many Requests"; break;
            case 500: descricao = "Internal Server Error"; break;
            case 502: descricao = "Bad Gateway"; break;
            case 503: descricao = "Service Unavailable"; break;
            default: descricao = status >= 400 ? "Error" : "OK";
        }
        StringBuilder cabecalho = new StringBuilder("HTTP/1.1 " + status + " " + descricao + "\r\n");
        // putIfAbsent: respeita Content-Type customizado definido antes pelo handler.
        cabecalhos.putIfAbsent("Content-Type", "application/json; charset=utf-8");
        cabecalhos.put("Content-Length", String.valueOf(status == 204 ? 0 : bytes.length));
        cabecalhos.put("Connection", "close");
        for (Map.Entry<String, String> item : cabecalhos.entrySet()) {
            cabecalho.append(item.getKey()).append(": ").append(item.getValue()).append("\r\n");
        }
        cabecalho.append("\r\n"); // linha vazia que separa cabecalhos do corpo
        // Cabecalhos sao ASCII por RFC; so o corpo carrega UTF-8.
        saida.write(cabecalho.toString().getBytes(StandardCharsets.US_ASCII));
        if (status != 204) {
            saida.write(bytes);
        }
        saida.flush();
        enviada = true;
    }

    /** Conveniencia: forca Content-Type JSON e delega para enviar(). */
    public void enviarJson(int status, String json) throws IOException {
        adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        enviar(status, json);
    }
}

