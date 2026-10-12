// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de média ponderada do boletim acadêmico e status final.
 * Endpoint: /api/notas/boletim
 */
public class BoletimHandler implements HttpHandler {

    private static final double NOTA_APROVACAO = 7.0;
    private static final double NOTA_RECUPERACAO = 5.0;

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        HttpUtils.aplicarHeadersCors(exchange);

        if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
            HttpUtils.enviarResposta(exchange, 204, "");
            return;
        }

        if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
            String body = HttpUtils.lerCorpoRequisicao(exchange);
            Map<String, String> params = HttpUtils.parseFormUrlEncoded(body);

            try {
                double n1 = Double.parseDouble(params.getOrDefault("p1", "0.0"));
                double w1 = Double.parseDouble(params.getOrDefault("peso1", "0.4"));

                double n2 = Double.parseDouble(params.getOrDefault("p2", "0.0"));
                double w2 = Double.parseDouble(params.getOrDefault("peso2", "0.4"));

                double n3 = Double.parseDouble(params.getOrDefault("trabalho", "0.0"));
                double w3 = Double.parseDouble(params.getOrDefault("pesoTrabalho", "0.2"));

                double somaNotasPesos = (n1 * w1) + (n2 * w2) + (n3 * w3);
                double somaPesos = w1 + w2 + w3;

                double media = somaPesos > 0 ? (somaNotasPesos / somaPesos) : 0.0;
                media = Math.round(media * 100.0) / 100.0;

                String status;
                if (media >= NOTA_APROVACAO) {
                    status = "APROVADO";
                } else if (media >= NOTA_RECUPERACAO) {
                    status = "EM_RECUPERACAO";
                } else {
                    status = "REPROVADO_POR_NOTA";
                }

                System.out.println("[LOG] Calculo Boletim -> Media: " + media + " | Status: " + status);
                HttpUtils.enviarResposta(exchange, 200, "Media Final: " + media + " | Status: " + status);

            } catch (Exception e) {
                HttpUtils.enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(exchange, 405, "Use POST.");
        }
    }
}

