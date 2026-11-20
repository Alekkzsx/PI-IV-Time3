// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.login;

import auth.abstratas.HandlerAuthPublicoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.conta.RecoveryHandler;
import auth.modules.email.SmtpCliente;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.LimitadorTentativas;
import auth.utils.OtpService;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Endpoint de login institucional com rate limiting, dummy hash anti-enumeracao e 2FA.
 * Rota: POST /api/auth/login
 */
public class LoginHandler extends HandlerAuthPublicoAbstrato {

    public LoginHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected boolean deveAplicarHeadersAuth() {
        return true;
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para login.";
    }

    @Override
    protected String tagLog() {
        return "LOGIN";
    }

    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        long inicio = System.currentTimeMillis();
        Map<String, Object> corpo = lerJsonObjeto(requisicao);

        String identidade = getPrimeiroTexto(corpo, "identidade", "identity");
        String senha = getPrimeiroTexto(corpo, "senha", "password");
        String perfilSolicitado = getPrimeiroTexto(corpo, "profile", "perfil");
        String ipCliente = extrairIpCliente(requisicao, "unknown");

        if (identidade == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'identidade' (ou 'identity') e obrigatorio.");
            return;
        }
        if (senha == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'senha' (ou 'password') e obrigatorio.");
            return;
        }

        // 1. Rate limiting
        LimitadorTentativas limitador = LimitadorTentativas.getInstance();
        if (!limitador.permitirTentativa(identidade, ipCliente)) {
            enviarBloqueio429(resposta, limitador.segundosRestantesBloqueio(identidade));
            return;
        }

        // 2. Autenticar no MongoDB (com dummy hash para usuarios inexistentes)
        UsuarioAutenticado usuario = repositorio.autenticar(identidade, senha);
        if (usuario == null) {
            if (perfilSolicitado != null && !perfilSolicitado.isEmpty()) {
                UsuarioAutenticado contaExistente = repositorio.buscarPorIdentidade(identidade);
                if (contaExistente == null && identidade.contains("@")) {
                    contaExistente = repositorio.buscarPorEmail(identidade);
                }
                if (contaExistente != null
                        && !RecoveryHandler.perfisCompativeis(perfilSolicitado, contaExistente.getProfile())) {
                    tratarPerfilInvalido(
                            resposta, limitador, contaExistente, identidade, perfilSolicitado, ipCliente, inicio);
                    return;
                }
            }
            tratarCredenciaisInvalidas(resposta, limitador, identidade, ipCliente, inicio);
            return;
        }

        if (perfilSolicitado != null && !RecoveryHandler.perfisCompativeis(perfilSolicitado, usuario.getProfile())) {
            tratarPerfilInvalido(resposta, limitador, usuario, identidade, perfilSolicitado, ipCliente, inicio);
            return;
        }

        // 3. Desafio 2FA se habilitado
        if (usuario.isTwoFactorEnabled()) {
            enviarDesafioDoisFatores(resposta, usuario, ipCliente, inicio);
            return;
        }

        // 4. Emitir par de tokens e persistir sessao
        UsuarioAutenticado usuarioFinal = repositorio.buscarPorId(usuario.getUserId());
        UsuarioAutenticado usuarioResp = usuarioFinal != null ? usuarioFinal : usuario;
        int sessionVersion = usuarioResp.getSessionVersion();

        Map<String, Object> respostaSucesso = emitirSessaoEPayloadTokens(
                requisicao, usuarioResp, sessionVersion, ipCliente, true, true);

        limitador.registrarSucesso(identidade, ipCliente);
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("profile", usuarioResp.getProfile());
        repositorio.registrarAuditoria(usuarioResp.getUserId(), "login_succeeded", usuarioResp.getUserId(), det, ipCliente);

        AuthHttpUtils.aplicarLatenciaPadronizada(inicio, true);
        enviarJson(resposta, 200, respostaSucesso);
    }

    private void enviarBloqueio429(RespostaHttp resposta, long segundosRestantes) throws IOException {
        resposta.adicionarCabecalho("Retry-After", String.valueOf(segundosRestantes));
        String msg = "Muitas tentativas de login. Tente novamente em " + segundosRestantes + " segundos.";
        Map<String, Object> erro = montarCorpoErro(429, "too_many_attempts", msg);
        erro.put("retryAfter", Long.valueOf(segundosRestantes));
        enviarJson(resposta, 429, erro);
    }

    private void tratarCredenciaisInvalidas(
            RespostaHttp resposta,
            LimitadorTentativas limitador,
            String identidade,
            String ipCliente,
            long inicio) throws IOException {
        String mensagem = limitador.registrarFalha(identidade, ipCliente);
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("identity", identidade);
        det.put("reason", "invalid_credentials");
        repositorio.registrarAuditoria("anonymous", "login_failed", identidade, det, ipCliente);

        AuthHttpUtils.aplicarLatenciaPadronizada(inicio, true);
        Map<String, Object> erro = montarCorpoErro(401, "invalid_credentials", mensagem);
        erro.put("maximo", Integer.valueOf(ConfigEnv.obterInteiro("MAX_FAILED_LOGIN_ATTEMPTS", 5)));
        enviarJson(resposta, 401, erro);
    }

    private void tratarPerfilInvalido(
            RespostaHttp resposta,
            LimitadorTentativas limitador,
            UsuarioAutenticado usuario,
            String identidade,
            String perfilSolicitado,
            String ipCliente,
            long inicio) throws IOException {
        limitador.registrarFalha(identidade, ipCliente);
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("requestedProfile", RecoveryHandler.normalizarPerfil(perfilSolicitado));
        det.put("actualProfile", RecoveryHandler.normalizarPerfil(usuario.getProfile()));
        repositorio.registrarAuditoria(usuario.getUserId(), "login_failed", usuario.getUserId(), det, ipCliente);
        AuthHttpUtils.aplicarLatenciaPadronizada(inicio, true);
        responderErro(
                resposta,
                403,
                "invalid_user_type",
                RecoveryHandler.construirMensagemPerfilIncompativel(perfilSolicitado, usuario.getProfile()));
    }

    private void enviarDesafioDoisFatores(
            RespostaHttp resposta, UsuarioAutenticado usuario, String ipCliente, long inicio) throws IOException {
        AuthHttpUtils.aplicarLatenciaPadronizada(inicio, true);

        String otpCode = OtpService.gerarCodigo();
        String otpHash = OtpService.hashOtp(otpCode, AuthHttpUtils.obterSegredoOtp());
        String challengeToken = UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");
        int ttlSegundos = AuthHttpUtils.obterTtlOtpSegundos();
        long expiraMillis = System.currentTimeMillis() + (long) ttlSegundos * 1000L;

        repositorio.salvarOtp(usuario.getIdentity(), otpHash, "2FA_LOGIN", expiraMillis);
        repositorio.salvarOtp(challengeToken, usuario.getIdentity(), "2FA_CHALLENGE", expiraMillis);

        if (SmtpCliente.isEmailValido(usuario.getEmail())) {
            SmtpCliente.enviarOtpComResultado(usuario.getEmail(), otpCode, usuario.getDisplayName())
                    .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                            usuario.getUserId(), "login_2fa_email", usuario.getEmail(), resultado, erro));
        } else {
            repositorio.registrarAuditoria(usuario.getUserId(), "login_2fa_missing_email", usuario.getUserId(), null, ipCliente);
        }

        Map<String, Object> desafio = new LinkedHashMap<String, Object>();
        desafio.put("status", Integer.valueOf(202));
        desafio.put("success", Boolean.TRUE);
        desafio.put("requiresTwoFactor", Boolean.TRUE);
        desafio.put("twoFactorRequired", Boolean.TRUE);
        desafio.put("challengeToken", challengeToken);
        desafio.put("identity", usuario.getIdentity());
        desafio.put("email", AuthHttpUtils.mascararEmail(usuario.getEmail()));
        desafio.put("expiresIn", Integer.valueOf(ttlSegundos));
        enviarJson(resposta, 202, desafio);
    }
}
