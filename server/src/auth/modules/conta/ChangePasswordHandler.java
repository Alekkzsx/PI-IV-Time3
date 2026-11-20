// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.conta;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.SenhaHasher;
import core.RequisicaoHttp;
import core.RespostaHttp;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint autenticado de alteracao de senha com logout global apos sucesso.
 * Rota: POST /api/auth/change-password
 */
public class ChangePasswordHandler extends HandlerAutenticadoAbstrato {

    public ChangePasswordHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public ChangePasswordHandler(RepositorioUsuarios repositorio) {
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
    protected String metodoPermitido() {
        return "POST";
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para alterar senha.";
    }

    @Override
    protected String tagLog() {
        return "CHANGE-PASSWORD";
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado usuario) throws Exception {
        Map<String, Object> corpo = lerJsonObjeto(requisicao);
        String senhaAtual = getPrimeiroTexto(corpo, "senhaAtual", "currentPassword");
        String novaSenha = getPrimeiroTexto(corpo, "novaSenha", "newPassword");

        if (senhaAtual == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'senhaAtual' (ou 'currentPassword') e obrigatorio.");
            return;
        }
        if (novaSenha == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'novaSenha' (ou 'newPassword') e obrigatorio.");
            return;
        }
        if (senhaAtual.equals(novaSenha)) {
            responderErro(resposta, 400, "invalid_request", "A nova senha deve ser diferente da senha atual.");
            return;
        }

        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
        if (!validacao.isValido()) {
            responderErro(resposta, 400, "invalid_request", validacao.getMensagem());
            return;
        }
        if (!repositorio.verificarSenhaAtual(usuario.getUserId(), senhaAtual)) {
            responderErro(resposta, 401, "invalid_password", "Senha atual incorreta.");
            return;
        }

        boolean atualizado = repositorio.atualizarSenha(usuario.getUserId(), novaSenha);
        if (!atualizado) {
            responderErro(resposta, 500, "internal_error", "Falha ao atualizar senha.");
            return;
        }

        repositorio.revogarTodasSessoes(usuario.getUserId());
        repositorio.registrarAuditoria(usuario.getUserId(), "password_changed", usuario.getUserId(), null);
        System.out.println("[AUTH] Senha alterada para usuario: " + usuario.getUserId() + " (todas as sessoes revogadas)");

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", Integer.valueOf(200));
        resp.put("message", "Senha alterada com sucesso. Todas as sessoes foram encerradas. Realize login novamente.");
        enviarJson(resposta, 200, resp);
    }
}
