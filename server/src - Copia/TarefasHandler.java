// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de dedução de notas em tarefas entregues com atraso.
 * Endpoint: /api/tarefas/calcular-nota
 */
public class TarefasHandler implements HttpHandler {

    private static final double PENALIDADE_DIARIA = 0.20;

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
                int diasAtraso = Integer.parseInt(params.getOrDefault("diasAtraso", "0"));
                double notaBase = Double.parseDouble(params.getOrDefault("notaBase", "10.0"));

                double notaMaximaPermitida = notaBase;

                if (diasAtraso > 0) {
                    double desconto = diasAtraso * PENALIDADE_DIARIA;
                    notaMaximaPermitida = notaBase * (1.0 - desconto);

                    if (notaMaximaPermitida < 0.0) {
                        notaMaximaPermitida = 0.0;
                    }
                }

                System.out.println("[LOG] Tarefa entregue com " + diasAtraso
                        + " dia(s) de atraso. Nota Maxima: " + notaMaximaPermitida);

                HttpUtils.enviarResposta(exchange, 200, "Nota Maxima Permitida: " + notaMaximaPermitida);

            } catch (Exception e) {
                HttpUtils.enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(exchange, 405, "Use POST.");
        }
    }
}

