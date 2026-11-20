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

    /**
     * Esqueleto fixo do ciclo de vida (final: subclasses nao podem quebrar a ordem).
     * A hierarquia de catch converte excecoes em respostas padronizadas:
     * ExcecaoHttpAbstrata usa o proprio status/codigo; SecurityException vira 401;
     * IllegalArgumentException vira 400; qualquer outra vira 500 generico logado.
     */
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
     * Unico metodo obrigatorio da subclasse: recebe a requisicao ja validada em metodo
     * e com headers aplicados; pode lancar qualquer excecao (o esqueleto converte em HTTP).
     */
    protected abstract void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception;

    // =========================================================================
    // GANCHOS CONFIGURAVEIS PELAS SUBCLASSES
    // =========================================================================

    /** Gancho: true adiciona headers anti-cache/seguranca de auth (rotas que emitem tokens). */
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

    /** Gancho: verbo HTTP unico aceito pela rota; null (padrao) aceita qualquer metodo. */
    protected String metodoPermitido() {
        return null;
    }

    /** Decide se o metodo recebido e aceito; subclasses com multiplos verbos sobrescrevem este. */
    protected boolean aceitaMetodo(String metodo) {
        String esperado = metodoPermitido();
        return esperado == null || esperado.equalsIgnoreCase(metodo);
    }

    /** Gancho: mensagem do 405; por padrao sugere o verbo correto ("Utilize POST..."). */
    protected String mensagemMetodoNaoPermitido() {
        String esperado = metodoPermitido();
        return esperado != null ? "Utilize " + esperado + " para este endpoint." : "Metodo nao permitido.";
    }

    /** Gancho: codigo semantico do 401 (subclasses de admin trocam para forbidden, etc.). */
    protected String codigoErroSeguranca() {
        return "unauthorized";
    }

    /** Gancho: mensagem do 400; pode ser sobrescrito para nao ecoar detalhes de parse interno. */
    protected String mensagemRequisicaoInvalida(IllegalArgumentException e) {
        return e.getMessage() != null ? e.getMessage() : "Corpo da requisicao invalido.";
    }

    /** Tag de log da classe concreta (ex.: LOGINHANDLER) para rastreio no console. */
    protected String tagLog() {
        return getClass().getSimpleName().toUpperCase();
    }

    /** Envelope de erro padrao {status, code, message, erro} compartilhado por todos os handlers. */
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

    /** Le o corpo como objeto JSON obrigatorio; corpo invalido lanca IllegalArgumentException -> 400. */
    protected Map<String, Object> lerJsonObjeto(RequisicaoHttp requisicao) {
        Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
        return corpo != null ? corpo : new LinkedHashMap<String, Object>();
    }

    /** Como lerJsonObjeto, mas corpo ausente/vazio devolve mapa vazio em vez de erro. */
    protected Map<String, Object> lerJsonObjetoOpcional(RequisicaoHttp requisicao) {
        String raw = requisicao.getCorpo();
        if (raw == null || raw.trim().isEmpty()) {
            return new LinkedHashMap<String, Object>();
        }
        return lerJsonObjeto(requisicao);
    }

    /** Extrai campo textual ja com trim; tipos nao-string e ausentes devolvem null. */
    protected String getString(Map<String, Object> mapa, String chave) {
        if (mapa == null) {
            return null;
        }
        Object valor = mapa.get(chave);
        return valor instanceof String ? ((String) valor).trim() : null;
    }

    /** Devolve o primeiro campo textual nao vazio entre os nomes dados (aceita aliases de payload). */
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

    /** IP do cliente para rate limit/auditoria (X-Forwarded-For > X-Real-IP > fallback do socket). */
    protected String extrairIpCliente(RequisicaoHttp requisicao, String fallback) {
        return RedeUtils.extrairIpCliente(requisicao, fallback);
    }

    /** Serializa o payload (Map/List/escalar) com Json.escrever e envia com Content-Type JSON. */
    protected void enviarJson(RespostaHttp resposta, int status, Object payload) throws IOException {
        resposta.enviarJson(status, Json.escrever(payload));
    }

    /** Atalho de erro padronizado: monta o envelope e envia na mesma chamada. */
    protected void responderErro(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        enviarJson(resposta, status, montarCorpoErro(status, codigo, mensagem));
    }
}
