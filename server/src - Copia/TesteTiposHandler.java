// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável por receber e validar a conversão de múltiplos tipos primitivos via POST.
 * Endpoint: /api/teste-tipos
 */
public class TesteTiposHandler implements HttpHandler {

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        HttpUtils.aplicarHeadersCors(exchange);

        if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
            HttpUtils.enviarResposta(exchange, 204, "");
            return;
        }

        if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
            String body = HttpUtils.lerCorpoRequisicao(exchange);
            System.out.println("\n[LOG] POST /api/teste-tipos - Corpo bruto: " + body);

            Map<String, String> params = HttpUtils.parseFormUrlEncoded(body);

            try {
                String textoFinal = params.getOrDefault("texto", "vazio");
                int inteiroFinal = Integer.parseInt(params.getOrDefault("inteiro", "0"));
                float flutuanteFinal = Float.parseFloat(params.getOrDefault("flutuante", "0.0"));
                double duploFinal = Double.parseDouble(params.getOrDefault("duplo", "0.0"));

                String strChar = params.getOrDefault("caractere", "X");
                char caractereFinal = !strChar.isEmpty() ? strChar.charAt(0) : 'X';

                System.out.println("--- Conversao de Tipos com Sucesso ---");
                System.out.println("String  (texto)     : " + textoFinal);
                System.out.println("int     (inteiro)   : " + inteiroFinal);
                System.out.println("float   (flutuante) : " + flutuanteFinal);
                System.out.println("double  (duplo)     : " + duploFinal);
                System.out.println("char    (caractere) : " + caractereFinal);
                System.out.println("---------------------------------------");

                String resposta = "OK - Tipos Processados: [" + textoFinal + ", "
                        + inteiroFinal + ", " + flutuanteFinal + ", "
                        + duploFinal + ", " + caractereFinal + "]";

                HttpUtils.enviarResposta(exchange, 200, resposta);

            } catch (Exception e) {
                System.err.println("[ERRO] Erro na conversao: " + e.getMessage());
                HttpUtils.enviarResposta(exchange, 400, "Erro de Conversao: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(exchange, 405, "Metodo nao permitido. Use POST.");
        }
    }
}

