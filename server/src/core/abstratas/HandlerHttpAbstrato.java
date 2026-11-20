// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core.abstratas;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.MonitorBackendAcademico;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.Json;
import utils.RedeUtils;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Classe abstrata base para todos os handlers HTTP do servidor nativo (Padrao Template Method).
 *
 * Centraliza o ciclo de vida comum de qualquer requisicao:
 * 1. Aplicacao de headers CORS e seguranca defensiva;
 * 2. Resposta automatica HTTP 204 para pre-flight OPTIONS;
 * 3. Validacao de metodo HTTP permitido (405 Method Not Allowed);
 * 4. Execucao do metodo abstrato processar(req, resp);
 * 5. Tratamento polimorfico centralizado de ExcecaoHttpAbstrata, SecurityException e erros inesperados.
 */
public abstract class HandlerHttpAbstrato implements ManipuladorHttp {

    @Override
    public final void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);
        if (deveAplicarHeadersAuth()) {
            HttpUtils.aplicarHeadersAuth(resposta);
        }

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!aceitaMetodo(requisicao.getMetodo())) {
            responderErro(resposta, 405, "method_not_allowed", mensagemMetodoNaoPermitido());
            return;
        }

        try {
            if (exigirBackendAcademicoOnline()) {
                MonitorBackendAcademico.garantirOnlineSeAtivo();
            }
            processar(requisicao, resposta);
        } catch (ExcecaoHttpAbstrata e) {
            responderErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (SecurityException e) {
            responderErro(resposta, 401, codigoErroSeguranca(), e.getMessage());
        } catch (IllegalArgumentException e) {
            responderErro(resposta, 400, "invalid_request", mensagemRequisicaoInvalida(e));
        } catch (Exception e) {
            System.err.println("[" + tagLog() + "] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            responderErro(resposta, 500, "internal_error", "Erro interno no servidor.");
        }
    }

    /**
     * Logica especifica do endpoint concreto.
     */
    protected abstract void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception;

    // =========================================================================
    // GANCHOS CONFIGURAVEIS PELAS SUBCLASSES
    // =========================================================================

    protected boolean deveAplicarHeadersAuth() {
        return false;
    }

    /**
     * Define se a rota exige que o Backend Academico (:3001) esteja online (politica Fail-Closed).
     * Sobrescrito para false apenas em rotas de diagnostico como HealthHandler.
     */
    protected boolean exigirBackendAcademicoOnline() {
        return true;
    }

    protected String metodoPermitido() {
        return null;
    }

    protected boolean aceitaMetodo(String metodo) {
        String esperado = metodoPermitido();
        return esperado == null || esperado.equalsIgnoreCase(metodo);
    }

    protected String mensagemMetodoNaoPermitido() {
        String esperado = metodoPermitido();
        return esperado != null ? "Utilize " + esperado + " para este endpoint." : "Metodo nao permitido.";
    }

    protected String codigoErroSeguranca() {
        return "unauthorized";
    }

    protected String mensagemRequisicaoInvalida(IllegalArgumentException e) {
        return e.getMessage() != null ? e.getMessage() : "Corpo da requisicao invalido.";
    }

    protected String tagLog() {
        return getClass().getSimpleName().toUpperCase();
    }

    protected Map<String, Object> montarCorpoErro(int status, String codigo, String mensagem) {
        String msg = mensagem != null ? mensagem : "Erro interno.";
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", Integer.valueOf(status));
        erro.put("code", codigo != null ? codigo : "error");
        erro.put("message", msg);
        erro.put("erro", msg);
        return erro;
    }

    // =========================================================================
    // UTILITARIOS COMPARTILHADOS PARA SUBCLASSES
    // =========================================================================

    protected Map<String, Object> lerJsonObjeto(RequisicaoHttp requisicao) {
        Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
        return corpo != null ? corpo : new LinkedHashMap<String, Object>();
    }

    protected Map<String, Object> lerJsonObjetoOpcional(RequisicaoHttp requisicao) {
        String raw = requisicao.getCorpo();
        if (raw == null || raw.trim().isEmpty()) {
            return new LinkedHashMap<String, Object>();
        }
        return lerJsonObjeto(requisicao);
    }

    protected String getString(Map<String, Object> mapa, String chave) {
        if (mapa == null) {
            return null;
        }
        Object valor = mapa.get(chave);
        return valor instanceof String ? ((String) valor).trim() : null;
    }

    protected String getPrimeiroTexto(Map<String, Object> mapa, String... chaves) {
        if (mapa == null || chaves == null) {
            return null;
        }
        for (String chave : chaves) {
            String valor = getString(mapa, chave);
            if (valor != null && !valor.isEmpty()) {
                return valor;
            }
        }
        return null;
    }

    protected String extrairIpCliente(RequisicaoHttp requisicao, String fallback) {
        return RedeUtils.extrairIpCliente(requisicao, fallback);
    }

    protected void enviarJson(RespostaHttp resposta, int status, Object payload) throws IOException {
        resposta.enviarJson(status, Json.escrever(payload));
    }

    protected void responderErro(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        enviarJson(resposta, status, montarCorpoErro(status, codigo, mensagem));
    }
}
