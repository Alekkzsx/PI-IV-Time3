// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de frequência acadêmica e validação de ajustes manuais.
 * Endpoint: /api/presenca
 */
public class PresencaHandler implements HttpHandler {

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
                int minutosAssistidos = Integer.parseInt(params.getOrDefault("minutosAssistidos", "0"));
                int duracaoTotal = Integer.parseInt(params.getOrDefault("duracaoTotal", "60"));

                String statusManual = params.get("statusManual");
                String resultado;

                if (statusManual != null && !statusManual.trim().isEmpty()) {
                    resultado = statusManual.toUpperCase() + " (Ajuste Manual do Professor)";
                } else {
                    double percentual = ((double) minutosAssistidos / duracaoTotal) * 100;

                    if (percentual >= 75.0) {
                        resultado = "PRESENCA_INTEGRAL (" + Math.round(percentual) + "%)";
                    } else if (percentual >= 50.0) {
                        resultado = "MEIA_PRESENCA (" + Math.round(percentual) + "%)";
                    } else {
                        resultado = "FALTA_AUTOMATICA (" + Math.round(percentual) + "%)";
                    }
                }

                System.out.println("[LOG] Calculo de Presenca: " + resultado);
                HttpUtils.enviarResposta(exchange, 200, "Resultado Presenca: " + resultado);

            } catch (Exception e) {
                HttpUtils.enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(exchange, 405, "Use POST.");
        }
    }
}

