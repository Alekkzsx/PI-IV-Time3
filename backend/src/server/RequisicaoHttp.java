// Desenvolvido por Guilherme Henrique Moreira
package server;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

// Representa uma requisição HTTP recebida pelo socket.
public class RequisicaoHttp {
    private final String metodo;
    private final String caminho;
    private final String corpo;

    private RequisicaoHttp(String metodo, String caminho, String corpo) {
        this.metodo = metodo;
        this.caminho = caminho;
        this.corpo = corpo;
    }

    public String getMetodo() { return metodo; }
    public String getCaminho() { return caminho; }
    public String getCorpo() { return corpo; }

    // Lê cabeçalhos e corpo respeitando Content-Length.
    public static RequisicaoHttp ler(InputStream entrada) throws IOException {
        String linhaInicial = lerLinha(entrada);
        if (linhaInicial == null || linhaInicial.isBlank()) throw new IOException("Requisicao vazia");
        String[] partes = linhaInicial.split(" ", 3);
        if (partes.length != 3 || !partes[2].startsWith("HTTP/1.")) throw new IOException("Linha HTTP invalida");
        if (!partes[1].startsWith("/") || partes[1].contains(" ")) throw new IOException("Caminho invalido");

        Map<String, String> cabecalhos = new HashMap<>();
        String linha;
        int quantidade = 0;
        while ((linha = lerLinha(entrada)) != null && !linha.isEmpty()) {
            quantidade += linha.length();
            if (quantidade > 16384) throw new IOException("Cabecalhos muito grandes");
            int separador = linha.indexOf(':');
            if (separador < 1) throw new IOException("Cabecalho invalido");
            String chave = linha.substring(0, separador).trim().toLowerCase(Locale.ROOT);
            if (cabecalhos.containsKey(chave)) throw new IOException("Cabecalho duplicado: " + chave);
            cabecalhos.put(chave, linha.substring(separador + 1).trim());
        }
        if (linha == null) throw new IOException("Cabecalhos incompletos");
        if (cabecalhos.containsKey("transfer-encoding")) throw new IOException("Transfer-Encoding nao suportado");
        int tamanho = 0;
        try {
            if (cabecalhos.containsKey("content-length")) tamanho = Integer.parseInt(cabecalhos.get("content-length"));
        } catch (NumberFormatException e) { throw new IOException("Content-Length invalido"); }
        if (tamanho < 0 || tamanho > 65536) throw new IOException("Corpo excede o limite de 64 KB");
        byte[] bytes = entrada.readNBytes(tamanho);
        if (bytes.length != tamanho) throw new IOException("Corpo HTTP incompleto");
        String caminho = partes[1].split("\\?", 2)[0];
        return new RequisicaoHttp(partes[0], caminho, new String(bytes, StandardCharsets.UTF_8));
    }

    // Evita BufferedReader para não consumir bytes do corpo antecipadamente.
    private static String lerLinha(InputStream entrada) throws IOException {
        StringBuilder resultado = new StringBuilder();
        int anterior = -1;
        int atual;
        while ((atual = entrada.read()) != -1) {
            if (atual == '\n') {
                if (anterior == '\r' && resultado.length() > 0) resultado.setLength(resultado.length() - 1);
                return resultado.toString();
            }
            resultado.append((char) atual);
            if (resultado.length() > 16384) throw new IOException("Linha HTTP muito grande");
            anterior = atual;
        }
        return null;
    }
}
