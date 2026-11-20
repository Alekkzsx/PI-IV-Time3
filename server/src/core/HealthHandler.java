// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core;

import core.abstratas.HandlerHttpAbstrato;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoints de healthcheck e readiness do servidor nativo Java.
 * Rotas suportadas:
 * - GET /health       (sempre 200 informando status do servico e conectividade do banco)
 * - GET /health/ready (200 se MongoDB acessivel, 503 se degradado)
 */
public class HealthHandler extends HandlerHttpAbstrato {
    private static final String SERVICE_NAME = "agmrm-identity-videocall";
    private final ConexaoMongo conexao;

    public HealthHandler(ConexaoMongo conexao) {
        this.conexao = conexao;
    }

    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        boolean readiness = "/health/ready".equalsIgnoreCase(requisicao.getCaminho());
        ConexaoMongo.EstadoSaudeBanco saude = conexao != null
                ? conexao.verificarSaudeBanco()
                : new ConexaoMongo.EstadoSaudeBanco(false, "database_unconfigured", "Conexao nao inicializada.");

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("status", readiness ? (saude.disponivel ? "ready" : "degraded") : "ok");
        payload.put("service", SERVICE_NAME);
        payload.put("database", saude.disponivel ? "connected" : "unreachable");

        if (!saude.disponivel) {
            if (readiness) {
                payload.put("code", saude.codigo);
                payload.put("message", saude.detalhe);
            } else {
                payload.put("databaseCode", saude.codigo);
                payload.put("databaseDetail", saude.detalhe);
            }
        }

        int httpStatus = (readiness && !saude.disponivel) ? 503 : 200;
        enviarJson(resposta, httpStatus, payload);
    }
}
