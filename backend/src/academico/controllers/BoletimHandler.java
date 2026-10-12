// Desenvolvido por Guilherme Henrique Moreira
package academico.controllers;

import server.HttpUtils;
import server.ManipuladorHttp;
import server.RequisicaoHttp;
import server.RespostaHttp;

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de média ponderada do boletim acadêmico e status final.
 * Endpoint: /api/notas/boletim
 */
public class BoletimHandler implements ManipuladorHttp {

    private static final double NOTA_APROVACAO = 7.0;
    private static final double NOTA_RECUPERACAO = 5.0;

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
                HttpUtils.enviarResposta(resposta, 200, "Media Final: " + media + " | Status: " + status);

            } catch (Exception e) {
                HttpUtils.enviarResposta(resposta, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(resposta, 405, "Use POST.");
        }
    }
}

