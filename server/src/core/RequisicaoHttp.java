// Desenvolvido por Guilherme Henrique Moreira
package core;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

// Representa uma requisicao HTTP recebida pelo socket TCP.
public class RequisicaoHttp {
    private final String metodo;
    private final String caminho;
    private final String queryParams;
    private final String corpo;
    private final Map<String, String> cabecalhos;

    private RequisicaoHttp(String metodo, String caminho, String queryParams, String corpo, Map<String, String> cabecalhos) {
        this.metodo = metodo;
        this.caminho = caminho;
        this.queryParams = queryParams;
        this.corpo = corpo;
        this.cabecalhos = cabecalhos;
    }

    public String getMetodo() { return metodo; }
    public String getCaminho() { return caminho; }
    public String getQueryParams() { return queryParams; }
    public String getCorpo() { return corpo; }
    public String getCabecalho(String nome) { return cabecalhos.get(nome.toLowerCase(Locale.ROOT)); }

    // Le cabecalhos e corpo com limites de seguranca contra estouro de memoria.
    public static RequisicaoHttp ler(InputStream entrada) throws IOException {
        String linhaInicial = lerLinha(entrada);
        if (linhaInicial == null || linhaInicial.trim().isEmpty()) {
            throw new IOException("Requisicao vazia");
        }
        String[] partes = linhaInicial.split(" ", 3);
        if (partes.length != 3 || !partes[2].startsWith("HTTP/1.")) {
            throw new IOException("Linha HTTP invalida");
        }
        if (!partes[1].startsWith("/") || partes[1].contains(" ")) {
            throw new IOException("Caminho invalido");
        }

        Map<String, String> cabecalhos = new HashMap<String, String>();
        String linha;
        int quantidade = 0;
        while ((linha = lerLinha(entrada)) != null && !linha.isEmpty()) {
            quantidade += linha.length();
            if (quantidade > 16384) throw new IOException("Cabecalhos muito grandes");
            int separador = linha.indexOf(':');
            if (separador < 1) throw new IOException("Cabecalho invalido");
            String chave = linha.substring(0, separador).trim().toLowerCase(Locale.ROOT);
            cabecalhos.put(chave, linha.substring(separador + 1).trim());
        }
        if (linha == null) throw new IOException("Cabecalhos incompletos");

        int tamanho = 0;
        if (cabecalhos.containsKey("content-length")) {
            try {
                tamanho = Integer.parseInt(cabecalhos.get("content-length"));
            } catch (NumberFormatException e) {
                throw new IOException("Content-Length invalido");
            }
        }
        if (tamanho < 0 || tamanho > 262144) { // limite seguro de 256 KB
            throw new IOException("Corpo excede o limite aceito");
        }

        byte[] bytes = new byte[tamanho];
        int totalLido = 0;
        while (totalLido < tamanho) {
            int lido = entrada.read(bytes, totalLido, tamanho - totalLido);
            if (lido == -1) break;
            totalLido += lido;
        }
        if (totalLido != tamanho) {
            throw new IOException("Corpo HTTP incompleto");
        }

        String rawPath = partes[1];
        String[] pathParts = rawPath.split("\\?", 2);
        String caminho = pathParts[0];
        String queryParams = pathParts.length > 1 ? pathParts[1] : "";

        return new RequisicaoHttp(partes[0], caminho, queryParams, new String(bytes, StandardCharsets.UTF_8), cabecalhos);
    }

    private static String lerLinha(InputStream entrada) throws IOException {
        StringBuilder resultado = new StringBuilder();
        int anterior = -1;
        int atual;
        while ((atual = entrada.read()) != -1) {
            if (atual == '\n') {
                if (anterior == '\r' && resultado.length() > 0) {
                    resultado.setLength(resultado.length() - 1);
                }
                return resultado.toString();
            }
            resultado.append((char) atual);
            if (resultado.length() > 16384) throw new IOException("Linha HTTP muito grande");
            anterior = atual;
        }
        return null;
    }
}

