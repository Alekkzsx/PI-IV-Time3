// Desenvolvido por Guilherme Henrique Moreira
package core;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

// Monta a resposta HTTP usando OutputStream nativo com suporte a CORS e JSON.
public class RespostaHttp {
    private final OutputStream saida;
    private final Map<String, String> cabecalhos = new LinkedHashMap<>();
    private boolean enviada = false;

    public RespostaHttp(OutputStream saida) { 
        this.saida = saida; 
    }

    public void adicionarCabecalho(String nome, String valor) { 
        cabecalhos.put(nome, valor); 
    }

    public boolean foiEnviada() { 
        return enviada; 
    }

    public void enviar(int status, String conteudo) throws IOException {
        if (enviada) throw new IOException("Resposta ja enviada");
        byte[] bytes = conteudo != null ? conteudo.getBytes(StandardCharsets.UTF_8) : new byte[0];
        String descricao;
        switch (status) {
            case 200: descricao = "OK"; break;
            case 201: descricao = "Created"; break;
            case 204: descricao = "No Content"; break;
            case 400: descricao = "Bad Request"; break;
            case 403: descricao = "Forbidden"; break;
            case 404: descricao = "Not Found"; break;
            case 405: descricao = "Method Not Allowed"; break;
            default: descricao = "Internal Server Error";
        }
        StringBuilder cabecalho = new StringBuilder("HTTP/1.1 " + status + " " + descricao + "\r\n");
        cabecalhos.putIfAbsent("Content-Type", "application/json; charset=utf-8");
        cabecalhos.put("Content-Length", String.valueOf(status == 204 ? 0 : bytes.length));
        cabecalhos.put("Connection", "close");
        for (Map.Entry<String, String> item : cabecalhos.entrySet()) {
            cabecalho.append(item.getKey()).append(": ").append(item.getValue()).append("\r\n");
        }
        cabecalho.append("\r\n");
        saida.write(cabecalho.toString().getBytes(StandardCharsets.US_ASCII));
        if (status != 204) {
            saida.write(bytes);
        }
        saida.flush();
        enviada = true;
    }

    public void enviarJson(int status, String json) throws IOException {
        adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        enviar(status, json);
    }
}

