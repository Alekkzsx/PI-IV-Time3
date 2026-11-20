// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.login;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.util.Map;

/**
 * Endpoint de inspecao e validacao de sessao autenticada.
 * Rotas: GET/POST /api/auth/session e /api/auth/me
 */
public class AuthSessionHandler extends HandlerAutenticadoAbstrato {

    public AuthSessionHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public AuthSessionHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected boolean deveAplicarHeadersAuth() {
        return false;
    }

    @Override
    protected boolean permitirTrocaSenhaPendente() {
        return true;
    }

    @Override
    protected boolean aceitaMetodo(String metodo) {
        return "GET".equalsIgnoreCase(metodo) || "POST".equalsIgnoreCase(metodo);
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize GET ou POST para verificar sessao.";
    }

    @Override
    protected Map<String, Object> montarCorpoErro(int status, String codigo, String mensagem) {
        Map<String, Object> erro = super.montarCorpoErro(status, codigo, mensagem);
        erro.put("authenticated", Boolean.FALSE);
        return erro;
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado u) throws Exception {
        Document doc = repositorio.buscarDocumentoAtivoPorId(u.getUserId());
        Map<String, Object> payload = AuthHttpUtils.montarPerfilPublico(u, doc);
        payload.put("status", Integer.valueOf(200));
        payload.put("authenticated", Boolean.TRUE);
        if (!u.getSessionId().isEmpty()) {
            payload.put("sessionId", u.getSessionId());
        }
        enviarJson(resposta, 200, payload);
    }

    public static Map<String, Object> montarPerfilPublico(UsuarioAutenticado u, Document doc) {
        return AuthHttpUtils.montarPerfilPublico(u, doc);
    }
}
