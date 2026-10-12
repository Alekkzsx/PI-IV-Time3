// Desenvolvido por Guilherme Henrique Moreira

import java.io.IOException;
import java.util.Map;

/**
 * Handler responsável pelo cálculo de dedução de notas em tarefas entregues com atraso.
 * Endpoint: /api/tarefas/calcular-nota
 */
public class TarefasHandler implements ManipuladorHttp {

    private static final double PENALIDADE_DIARIA = 0.20;

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

                HttpUtils.enviarResposta(resposta, 200, "Nota Maxima Permitida: " + notaMaximaPermitida);

            } catch (Exception e) {
                HttpUtils.enviarResposta(resposta, 400, "Dados invalidos: " + e.getMessage());
            }

        } else {
            HttpUtils.enviarResposta(resposta, 405, "Use POST.");
        }
    }
}

