// Desenvolvido por Guilherme Henrique Moreira

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de frequência acadêmica e validação de ajustes manuais.
 * Endpoint: /api/presenca
 */
public class PresencaHandler implements ManipuladorHttp {

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            HttpUtils.enviarResposta(resposta, 204, "");
            return;
        }

        if ("POST".equalsIgnoreCase(requisicao.getMetodo())) {
            String body = HttpUtils.lerCorpoRequisicao(requisicao);
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
                HttpUtils.enviarResposta(resposta, 200, "Resultado Presenca: " + resultado);

            } catch (Exception e) {
                HttpUtils.enviarResposta(resposta, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(resposta, 405, "Use POST.");
        }
    }
}

