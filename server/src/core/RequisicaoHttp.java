// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

// Representa uma requisicao HTTP recebida pelo socket TCP.
/**
 * DTO imutavel de uma requisicao HTTP/1.1 lida diretamente do socket TCP.
 * Construido apenas pela factory {@link #ler(InputStream)}, que parseia request line,
 * cabecalhos (normalizados para minusculo, pois nomes de header sao case-insensitive)
 * e corpo dimensionado por Content-Length. Limites rigidos protegem contra exaustao de memoria.
 */
public class RequisicaoHttp {
    private final String metodo;
    private final String caminho;
    private final String queryParams;
    private final String corpo;
    private final Map<String, String> cabecalhos;

    // Construtor privado: a unica forma valida de criar e a factory ler(), que garante o parse completo.
    private RequisicaoHttp(String metodo, String caminho, String queryParams, String corpo, Map<String, String> cabecalhos) {
        this.metodo = metodo;
        this.caminho = caminho;
        this.queryParams = queryParams;
        this.corpo = corpo;
        this.cabecalhos = cabecalhos;
    }

    /** @return verbo HTTP conforme recebido (GET, POST, PATCH...). */
    public String getMetodo() { return metodo; }
    /** @return caminho da URL sem query string (ex.: "/api/auth/login"). */
    public String getCaminho() { return caminho; }
    /** @return query string crua apos o '?', ainda nao decodificada ("" se ausente). */
    public String getQueryParams() { return queryParams; }
    /** @return corpo decodificado em UTF-8 ("" quando Content-Length e 0/ausente). */
    public String getCorpo() { return corpo; }
    /** Busca cabecalho de forma case-insensitive (nomes sao armazenados em minusculo). */
    public String getCabecalho(String nome) { return cabecalhos.get(nome.toLowerCase(Locale.ROOT)); }

    // Le cabecalhos e corpo com limites de seguranca contra estouro de memoria.
    /**
     * Factory que le uma requisicao completa do stream do socket:
     * request line -> cabecalhos ate a linha vazia -> corpo de exatamente Content-Length bytes.
     *
     * @param entrada stream de entrada do socket do cliente
     * @return requisicao imutavel pronta para roteamento
     * @throws IOException se o protocolo for violado, os limites forem excedidos ou o corpo vier truncado
     */
    public static RequisicaoHttp ler(InputStream entrada) throws IOException {
        String linhaInicial = lerLinha(entrada);
        if (linhaInicial == null || linhaInicial.trim().isEmpty()) {
            throw new IOException("Requisicao vazia");
        }
        // Request line tem exatamente 3 tokens: METODO CAMINHO HTTP/1.x.
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
            // Teto acumulado de 16 KB de cabecalhos: barra flood de headers maliciosos.
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

        // read() pode devolver menos bytes que o pedido: loop ate completar exatamente Content-Length.
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

        // Separa caminho e query string no primeiro '?' (a query pode conter '?' literais).
        String rawPath = partes[1];
        String[] pathParts = rawPath.split("\\?", 2);
        String caminho = pathParts[0];
        String queryParams = pathParts.length > 1 ? pathParts[1] : "";

        return new RequisicaoHttp(partes[0], caminho, queryParams, new String(bytes, StandardCharsets.UTF_8), cabecalhos);
    }

    /**
     * Le uma linha terminada em LF, removendo o CR anterior (protocolo HTTP usa CRLF).
     * Le byte a byte de proposito: nao pode consumir alem do fim da linha, pois o corpo
     * vem em seguida no mesmo stream.
     *
     * @return linha sem o terminador, ou null se o stream acabou antes de qualquer byte
     */
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

