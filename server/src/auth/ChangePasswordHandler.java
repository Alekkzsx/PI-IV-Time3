// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.Json;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de alteracao de senha para usuarios autenticados.
 * Rota: POST /api/auth/change-password
 *
 * Requer autenticacao via Bearer token.
 * Valida a senha atual antes de permitir a alteracao.
 * Apos sucesso, revoga todas as sessoes existentes do usuario (logout global).
 *
 * Header: Authorization: Bearer <access_token>
 * Body: { "senhaAtual": "string", "novaSenha": "string" }
 *
 * Response 200: { "status": 200, "message": "Senha alterada com sucesso." }
 * Response 400: { "erro": "..." } (senha invalida, complexidade insuficiente)
 * Response 401: { "erro": "..." } (nao autenticado ou senha atual incorreta)
 */
public class ChangePasswordHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public ChangePasswordHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public ChangePasswordHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST para alterar senha.");
            return;
        }

        try {
            // Autenticar o usuario (exige token valido)
            UsuarioAutenticado usuario = JwtAuthValidator.autenticarObrigatorio(requisicao);

            // Parsear body
            Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
            if (corpo == null) corpo = new LinkedHashMap<String, Object>();

            String senhaAtual = getString(corpo, "senhaAtual");
            if (senhaAtual == null || senhaAtual.trim().isEmpty()) {
                senhaAtual = getString(corpo, "currentPassword");
            }
            String novaSenha = getString(corpo, "novaSenha");
            if (novaSenha == null || novaSenha.trim().isEmpty()) {
                novaSenha = getString(corpo, "newPassword");
            }

            // Validar campos
            if (senhaAtual == null || senhaAtual.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'senhaAtual' (ou 'currentPassword') e obrigatorio.");
                return;
            }
            if (novaSenha == null || novaSenha.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'novaSenha' (ou 'newPassword') e obrigatorio.");
                return;
            }

            // Nova senha nao pode ser igual a atual
            if (senhaAtual.equals(novaSenha)) {
                enviarErro(resposta, 400, "A nova senha deve ser diferente da senha atual.");
                return;
            }

            // Validar complexidade da nova senha
            SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
            if (!validacao.isValido()) {
                enviarErro(resposta, 400, validacao.getMensagem());
                return;
            }

            // Verificar senha atual no MongoDB
            RepositorioUsuarios repo = this.repositorio;
            boolean senhaAtualCorreta = repo.verificarSenhaAtual(usuario.getUserId(), senhaAtual);

            if (!senhaAtualCorreta) {
                enviarErro(resposta, 401, "Senha atual incorreta.");
                return;
            }

            // Atualizar senha
            boolean atualizado = repo.atualizarSenha(usuario.getUserId(), novaSenha);

            if (atualizado) {
                // Revogar todas as sessoes (logout global)
                repo.revogarTodasSessoes(usuario.getUserId());
                System.out.println("[AUTH] Senha alterada para usuario: " + usuario.getUserId() + " (todas as sessoes revogadas)");
            }

            if (!atualizado) {
                enviarErro(resposta, 500, "Falha ao atualizar senha.");
                return;
            }

            Map<String, Object> resp = new LinkedHashMap<String, Object>();
            resp.put("status", 200);
            resp.put("message", "Senha alterada com sucesso. Todas as sessoes foram encerradas. Realize login novamente.");
            resposta.enviarJson(200, Json.escrever(resp));

        } catch (SecurityException e) {
            enviarErro(resposta, 401, e.getMessage());
        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "Corpo da requisicao invalido: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[CHANGE-PASSWORD] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    private String getString(Map<String, Object> mapa, String chave) {
        Object valor = mapa.get(chave);
        if (valor instanceof String) return ((String) valor).trim();
        return null;
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
