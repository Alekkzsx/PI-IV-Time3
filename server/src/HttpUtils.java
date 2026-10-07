// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpExchange; //não pode usar biblioteca httpserver

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * Utilitários para tratamento de requisições e respostas HTTP no servidor nativo.
 */
public final class HttpUtils {

    private HttpUtils() {
        // Construtor privado para classe utilitária
    }

    /**
     * Aplica cabeçalhos CORS na resposta HTTP permitindo origens cruzadas.
     */
    public static void aplicarHeadersCors(HttpExchange exchange) {
        exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    /**
     * Lê o corpo completo da requisição HTTP como String UTF-8.
     */
    public static String lerCorpoRequisicao(HttpExchange exchange) throws IOException {
        InputStream is = exchange.getRequestBody();
        BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
        StringBuilder bodyBuilder = new StringBuilder();

        String linha;
        while ((linha = reader.readLine()) != null) {
            bodyBuilder.append(linha);
        }

        return bodyBuilder.toString();
    }

    /**
     * Converte payload no formato application/x-www-form-urlencoded em um mapa de chave-valor.
     */
    public static Map<String, String> parseFormUrlEncoded(String body) {
        Map<String, String> mapa = new HashMap<>();

        if (body == null || body.trim().isEmpty()) {
            return mapa;
        }

        String[] parametros = body.split("&");
        for (String param : parametros) {
            String[] chaveValor = param.split("=");
            if (chaveValor.length == 2) {
                mapa.put(chaveValor[0], chaveValor[1]);
            } else if (chaveValor.length == 1) {
                mapa.put(chaveValor[0], "");
            }
        }

        return mapa;
    }

    /**
     * Envia resposta HTTP com código de status e fecha o corpo da resposta.
     */
    public static void enviarResposta(HttpExchange exchange, int statusCode, String resposta) throws IOException {
        byte[] bytes = resposta.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(statusCode, bytes.length);

        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }
}

