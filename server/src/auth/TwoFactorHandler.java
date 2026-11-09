// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;
import utils.Json;

import org.bson.Document;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint de verificacao de 2FA (autenticacao de dois fatores).
 * Rota: POST /api/auth/verify-two-factor
 *
 * Recebe a identidade e o codigo OTP enviado por email.
 * Se valido, gera o par de tokens (access + refresh) para completar o login.
 *
 * Body: { "identity": "string", "code": "string" }
 *
 * Response 200: { "token": "...", "refreshToken": "...", "usuario": {...} }
 * Response 401: { "erro": "..." }
 */
public class TwoFactorHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public TwoFactorHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public TwoFactorHandler(RepositorioUsuarios repositorio) {
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
            enviarErro(resposta, 405, "Utilize POST para verificar 2FA.");
            return;
        }

        long inicioProcessamento = System.currentTimeMillis();

        try {
            Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
            if (corpo == null) corpo = new LinkedHashMap<String, Object>();

            String identity = getString(corpo, "identity");
            String challengeToken = getString(corpo, "challengeToken");
            String code = getString(corpo, "code");

            if ((identity == null || identity.trim().isEmpty()) && challengeToken != null && !challengeToken.trim().isEmpty()) {
                Document challengeDoc = repositorio.buscarOtp(challengeToken.trim(), "2FA_CHALLENGE");
                if (challengeDoc != null) {
                    identity = challengeDoc.getString("otpHash");
                }
            }

            if (identity == null || identity.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'identity' ou 'challengeToken' e obrigatorio.");
                return;
            }
            if (code == null || code.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'code' e obrigatorio.");
                return;
            }

            String normalizedIdentity = identity.trim().toLowerCase();
            String otpSecret = ConfigEnv.obter("AUTH_OTP_SECRET",
                    "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890");

            RepositorioUsuarios repo = this.repositorio;

            // Buscar OTP do tipo 2FA_LOGIN para esta identidade
            Document otpDoc = repo.buscarOtp(normalizedIdentity, "2FA_LOGIN");
            if (otpDoc == null) {
                repo.fechar();
                aplicarLatenciaPadronizada(inicioProcessamento);
                enviarErro(resposta, 401, "Codigo de verificacao expirado ou nao encontrado. Solicite um novo login.");
                return;
            }

            // Verificar tentativas
            int tentativas = otpDoc.getInteger("tentativas", 0);
            if (OtpService.tentativasExcedidas(tentativas)) {
                repo.removerOtp(normalizedIdentity, "2FA_LOGIN");
                repo.fechar();
                aplicarLatenciaPadronizada(inicioProcessamento);
                enviarErro(resposta, 429, "Numero maximo de tentativas excedido. Solicite um novo codigo.");
                return;
            }

            // Verificar expiracao
            java.util.Date expiresAt = otpDoc.getDate("expiresAt");
            if (expiresAt != null && expiresAt.getTime() < System.currentTimeMillis()) {
                repo.removerOtp(normalizedIdentity, "2FA_LOGIN");
                repo.fechar();
                aplicarLatenciaPadronizada(inicioProcessamento);
                enviarErro(resposta, 401, "Codigo de verificacao expirado. Solicite um novo login.");
                return;
            }

            // Validar codigo OTP
            String hashArmazenado = otpDoc.getString("otpHash");
            boolean valido = OtpService.validar(code, hashArmazenado, otpSecret);

            if (!valido) {
                repo.incrementarTentativasOtp(normalizedIdentity, "2FA_LOGIN");
                repo.fechar();
                aplicarLatenciaPadronizada(inicioProcessamento);
                enviarErro(resposta, 401, "Codigo de verificacao invalido.");
                return;
            }

            // OTP valido! Remover e gerar tokens
            repo.removerOtp(normalizedIdentity, "2FA_LOGIN");

            UsuarioAutenticado usuario = repo.buscarPorIdentidade(normalizedIdentity);
            if (usuario == null) {
                repo.fechar();
                enviarErro(resposta, 401, "Usuario nao encontrado.");
                return;
            }

            // Gerar par de tokens
            int sessionVersion = usuario.getSessionVersion();
            JwtGerador.ParTokens parTokens = JwtGerador.gerarParTokens(usuario, sessionVersion);

            // Persistir sessao
            String jti = JwtGerador.extrairJti(parTokens.getAccessToken());
            long expira = JwtGerador.extrairExpiracaoMillis(parTokens.getAccessToken());
            if (jti != null) {
                repo.criarSessao(usuario.getUserId(), jti, expira);
            }

            repo.fechar();

            // Construir resposta com dados reais do MongoDB
            Map<String, Object> payloadUsuario = new LinkedHashMap<String, Object>();
            payloadUsuario.put("id", usuario.getUserId());
            payloadUsuario.put("identidade", usuario.getIdentity());
            payloadUsuario.put("identity", usuario.getIdentity());
            payloadUsuario.put("perfil", usuario.getProfile());
            payloadUsuario.put("profile", usuario.getProfile());
            if (!usuario.getDisplayName().isEmpty()) {
                payloadUsuario.put("nome", usuario.getDisplayName());
                payloadUsuario.put("displayName", usuario.getDisplayName());
            }
            if (!usuario.getEmail().isEmpty()) {
                payloadUsuario.put("email", usuario.getEmail());
            }
            if (!usuario.getDepartmentOrCourse().isEmpty()) {
                payloadUsuario.put("departmentOrCourse", usuario.getDepartmentOrCourse());
                payloadUsuario.put("department", usuario.getDepartmentOrCourse());
            }
            if (!usuario.getCampus().isEmpty()) {
                payloadUsuario.put("campus", usuario.getCampus());
            }
            if (!usuario.getSemester().isEmpty()) {
                payloadUsuario.put("semester", usuario.getSemester());
            }
            if (!usuario.getShift().isEmpty()) {
                payloadUsuario.put("shift", usuario.getShift());
            }

            Map<String, Object> resp = new LinkedHashMap<String, Object>();
            resp.put("status", 200);
            resp.put("success", true);
            resp.put("accessToken", parTokens.getAccessToken());
            resp.put("token", parTokens.getAccessToken());
            resp.put("refreshToken", parTokens.getRefreshToken());
            resp.put("usuario", payloadUsuario);
            resp.put("user", payloadUsuario);

            aplicarLatenciaPadronizada(inicioProcessamento);

            resposta.enviarJson(200, Json.escrever(resp));

        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "Corpo da requisicao invalido: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[2FA] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    private String getString(Map<String, Object> mapa, String chave) {
        Object valor = mapa.get(chave);
        if (valor instanceof String) return ((String) valor).trim();
        return null;
    }

    private void aplicarLatenciaPadronizada(long inicio) {
        long latenciaAlvo = ConfigEnv.obterInteiro("STANDARDIZED_AUTH_LATENCY_MS", 1000);
        long decorrido = System.currentTimeMillis() - inicio;
        long restante = latenciaAlvo - decorrido;
        if (restante > 0) {
            try { Thread.sleep(restante); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
        }
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
