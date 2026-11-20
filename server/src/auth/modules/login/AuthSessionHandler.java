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

    /** Perfil/sessao nao emite tokens: usa so os headers padrao, sem o pacote anti-cache de emissao. */
    @Override
    protected boolean deveAplicarHeadersAuth() {
        return false;
    }

    /**
     * /me precisa responder MESMO com troca de senha pendente: e assim que o frontend
     * descobre requirePasswordChange e redireciona para a tela de troca.
     */
    @Override
    protected boolean permitirTrocaSenhaPendente() {
        return true;
    }

    /** Aceita GET (consulta padrao) e POST (clientes que evitam cache de GET). */
    @Override
    protected boolean aceitaMetodo(String metodo) {
        return "GET".equalsIgnoreCase(metodo) || "POST".equalsIgnoreCase(metodo);
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize GET ou POST para verificar sessao.";
    }

    /** Contrato do frontend: toda resposta de erro de sessao carrega authenticated=false. */
    @Override
    protected Map<String, Object> montarCorpoErro(int status, String codigo, String mensagem) {
        Map<String, Object> erro = super.montarCorpoErro(status, codigo, mensagem);
        erro.put("authenticated", Boolean.FALSE);
        return erro;
    }

    /** Sessao valida (guarda da superclasse ja passou): devolve perfil publico + authenticated=true + sessionId. */
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

    /** Delegador estatico mantido por compatibilidade com chamadas antigas (implementacao em AuthHttpUtils). */
    public static Map<String, Object> montarPerfilPublico(UsuarioAutenticado u, Document doc) {
        return AuthHttpUtils.montarPerfilPublico(u, doc);
    }
}
