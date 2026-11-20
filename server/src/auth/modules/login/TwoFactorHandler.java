// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
package auth.modules.login;

import auth.abstratas.HandlerAuthPublicoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.OtpService;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de verificacao de 2FA (codigo OTP por e-mail ou codigo de backup single-use).
 * Rota: POST /api/auth/verify-two-factor
 */
public class TwoFactorHandler extends HandlerAuthPublicoAbstrato {

    public TwoFactorHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public TwoFactorHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para verificar 2FA.";
    }

    @Override
    protected String tagLog() {
        return "2FA";
    }

    /**
     * Verifica o segundo fator e conclui o login:
     * resolve a identidade (direta ou via challengeToken) -> localiza o OTP 2FA_LOGIN ->
     * valida tentativas/expiracao/codigo (ou consome um backup code single-use) ->
     * limpa os registros do desafio -> emite sessao + tokens -> audita o metodo usado.
     */
    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        long inicio = System.currentTimeMillis();
        Map<String, Object> corpo = lerJsonObjeto(requisicao);

        String identity = getString(corpo, "identity");
        String challengeToken = getString(corpo, "challengeToken");
        String code = getString(corpo, "code");

        if ((identity == null || identity.isEmpty()) && challengeToken != null && !challengeToken.isEmpty()) {
            // No registro 2FA_CHALLENGE o campo otpHash guarda a IDENTIDADE (vinculo token->conta).
            Document challengeDoc = repositorio.buscarOtp(challengeToken, "2FA_CHALLENGE");
            if (challengeDoc != null) {
                identity = challengeDoc.getString("otpHash");
            }
        }
        if (identity == null || identity.isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Campo 'identity' ou 'challengeToken' e obrigatorio.");
            return;
        }
        if (code == null || code.isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Campo 'code' e obrigatorio.");
            return;
        }

        String normalizedIdentity = identity.trim().toLowerCase();
        UsuarioAutenticado usuarioAlvo = repositorio.buscarPorIdentidade(normalizedIdentity);
        boolean usadoBackupCode = false;

        Document otpDoc = repositorio.buscarOtp(normalizedIdentity, "2FA_LOGIN");
        if (otpDoc == null) {
            // Sem OTP ativo: ainda aceita backup code (uso unico, consumido atomicamente no banco).
            if (usuarioAlvo != null && repositorio.consumirCodigoBackup(usuarioAlvo.getUserId(), code)) {
                usadoBackupCode = true;
            } else {
                AuthHttpUtils.aplicarLatenciaPadronizada(inicio, false);
                responderErro(resposta, 401, "invalid_two_factor",
                        "Codigo de verificacao expirado ou nao encontrado. Solicite um novo login.");
                return;
            }
        }

        if (!usadoBackupCode) {
            int tentativas = otpDoc.getInteger("tentativas", 0);
            // Estourou o limite de tentativas: o OTP e destruido (forca novo login, nao so novo codigo).
            if (OtpService.tentativasExcedidas(tentativas)) {
                repositorio.removerOtp(normalizedIdentity, "2FA_LOGIN");
                AuthHttpUtils.aplicarLatenciaPadronizada(inicio, false);
                responderErro(resposta, 429, "too_many_attempts",
                        "Numero maximo de tentativas excedido. Solicite um novo codigo.");
                return;
            }
            Date expiresAt = otpDoc.getDate("expiresAt");
            if (expiresAt != null && expiresAt.getTime() < System.currentTimeMillis()) {
                repositorio.removerOtp(normalizedIdentity, "2FA_LOGIN");
                AuthHttpUtils.aplicarLatenciaPadronizada(inicio, false);
                responderErro(resposta, 401, "invalid_two_factor",
                        "Codigo de verificacao expirado. Solicite um novo login.");
                return;
            }
            boolean valido = OtpService.validar(code, otpDoc.getString("otpHash"), AuthHttpUtils.obterSegredoOtp());
            if (!valido) {
                // Codigo errado pode ser um backup code: tenta consumir antes de contar a falha.
                if (usuarioAlvo != null && repositorio.consumirCodigoBackup(usuarioAlvo.getUserId(), code)) {
                    usadoBackupCode = true;
                } else {
                    repositorio.incrementarTentativasOtp(normalizedIdentity, "2FA_LOGIN");
                    AuthHttpUtils.aplicarLatenciaPadronizada(inicio, false);
                    responderErro(resposta, 401, "invalid_two_factor", "Codigo de verificacao invalido.");
                    return;
                }
            }
        }

        // Sucesso: consome o OTP e o challenge (uso unico - replay do mesmo codigo falha).
        repositorio.removerOtp(normalizedIdentity, "2FA_LOGIN");
        if (challengeToken != null && !challengeToken.isEmpty()) {
            repositorio.removerOtp(challengeToken, "2FA_CHALLENGE");
        }

        UsuarioAutenticado usuario = usuarioAlvo != null ? usuarioAlvo : repositorio.buscarPorIdentidade(normalizedIdentity);
        if (usuario == null) {
            responderErro(resposta, 401, "invalid_two_factor", "Usuario nao encontrado.");
            return;
        }

        String ipCliente = extrairIpCliente(requisicao, "127.0.0.1");
        Map<String, Object> resp = emitirSessaoEPayloadTokens(
                requisicao, usuario, usuario.getSessionVersion(), ipCliente, true, true);

        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("method", usadoBackupCode ? "backup_code" : "email_otp");
        repositorio.registrarAuditoria(usuario.getUserId(), "two_factor_verified", usuario.getUserId(), det, ipCliente);

        AuthHttpUtils.aplicarLatenciaPadronizada(inicio, false);
        enviarJson(resposta, 200, resp);
    }
}
