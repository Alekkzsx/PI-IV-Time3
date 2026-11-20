// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package auth.modules.conta;

import auth.abstratas.HandlerAuthPublicoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.AuthHttpUtils;
import auth.utils.JwtAuthValidator;
import auth.utils.JwtGerador;
import auth.utils.OtpService;
import auth.utils.RevogacaoTokens;
import auth.utils.SenhaHasher;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.ConfigEnv;

import java.io.IOException;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Fluxo completo de recuperacao de senha via OTP e grant single-use anti-replay.
 * Rotas:
 * - POST /api/auth/send-recovery-otp
 * - POST /api/auth/verify-recovery-otp
 * - POST /api/auth/reset-password
 *
 * Maquina de estados: send gera OTP (HMAC no banco, enviado por e-mail) -> verify
 * valida o OTP e emite um recovery token JWT (15min) + grant persistido -> reset
 * CONSOME o grant atomicamente (uso unico) e troca a senha com logout global.
 * Cada etapa invalida a anterior: OTP consumido no verify, grant consumido no reset.
 */
public class RecoveryHandler extends HandlerAuthPublicoAbstrato {

    public RecoveryHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public RecoveryHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST.";
    }

    @Override
    protected String tagLog() {
        return "RECOVERY";
    }

    /** Despacho por sufixo do caminho: uma instancia atende as tres etapas do fluxo. */
    @Override
    protected void processar(RequisicaoHttp requisicao, RespostaHttp resposta) throws Exception {
        String caminho = requisicao.getCaminho();
        if (caminho.endsWith("/send-recovery-otp")) {
            tratarEnvioOtp(requisicao, resposta);
        } else if (caminho.endsWith("/verify-recovery-otp")) {
            tratarVerificacaoOtp(requisicao, resposta);
        } else if (caminho.endsWith("/reset-password")) {
            tratarRedefinicaoSenha(requisicao, resposta);
        } else {
            responderErro(resposta, 404, "not_found", "Endpoint de recuperacao nao encontrado.");
        }
    }

    /**
     * Etapa 1 - send-recovery-otp: localiza a conta por e-mail OU identidade,
     * valida perfil do portal e e-mail cadastrado, gera o OTP e dispara o e-mail
     * em background. Contas inexistentes recebem 404 explicito (decisao de UX deste
     * fluxo), com auditoria e latencia padronizada para dificultar varredura em massa.
     */
    private void tratarEnvioOtp(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = lerJsonObjeto(requisicao);
        String email = getString(corpo, "email");
        String identity = getString(corpo, "identity");
        String perfilSolicitado = getPrimeiroTexto(corpo, "profile", "perfil");
        boolean temEmail = email != null && !email.isEmpty();
        boolean temIdentity = identity != null && !identity.isEmpty();

        if (!temEmail && !temIdentity) {
            responderErro(resposta, 400, "invalid_request",
                    "Informe o e-mail ou identificador cadastrado para recuperar a senha.");
            return;
        }

        String chaveConsultada = temEmail ? email : identity;
        UsuarioAutenticado localizado = temEmail
                ? repositorio.buscarPorEmail(email)
                : repositorio.buscarPorIdentidade(identity);
        // Identidade com '@' pode ser o e-mail: tenta o segundo indice antes de desistir.
        if (localizado == null && temIdentity && identity.contains("@")) {
            localizado = repositorio.buscarPorEmail(identity);
        }
        final UsuarioAutenticado usuario = localizado;

        if (usuario == null) {
            Map<String, Object> det = new LinkedHashMap<String, Object>();
            det.put("queriedValue", chaveConsultada);
            repositorio.registrarAuditoria("anonymous", "password_recovery_not_registered", chaveConsultada, det);
            AuthHttpUtils.aplicarLatenciaPadronizada(0L, false);
            responderErro(resposta, 404, "email_not_registered",
                    "E-mail ou identificador nao cadastrado no sistema.");
            return;
        }

        if (perfilSolicitado != null && !perfilSolicitado.isEmpty()
                && !perfisCompativeis(perfilSolicitado, usuario.getProfile())) {
            Map<String, Object> det = new LinkedHashMap<String, Object>();
            det.put("queriedValue", chaveConsultada);
            det.put("requestedProfile", normalizarPerfil(perfilSolicitado));
            det.put("actualProfile", normalizarPerfil(usuario.getProfile()));
            repositorio.registrarAuditoria(
                    usuario.getUserId(), "password_recovery_invalid_profile", usuario.getUserId(), det);
            AuthHttpUtils.aplicarLatenciaPadronizada(0L, false);
            responderErro(resposta, 403, "invalid_user_type",
                    construirMensagemPerfilIncompativel(perfilSolicitado, usuario.getProfile()));
            return;
        }

        if (!SmtpCliente.isEmailValido(usuario.getEmail())) {
            Map<String, Object> det = new LinkedHashMap<String, Object>();
            det.put("identity", usuario.getIdentity());
            repositorio.registrarAuditoria(usuario.getUserId(), "password_recovery_missing_email", usuario.getUserId(), det);
            AuthHttpUtils.aplicarLatenciaPadronizada(0L, false);
            responderErro(resposta, 422, "email_not_registered",
                    "Esta conta nao possui um e-mail valido cadastrado no sistema.");
            return;
        }

        String otpCode = OtpService.gerarCodigo();
        String otpHash = OtpService.hashOtp(otpCode, AuthHttpUtils.obterSegredoOtp());
        int ttlSegundos = AuthHttpUtils.obterTtlOtpSegundos();
        long expiraEmMillis = System.currentTimeMillis() + (long) ttlSegundos * 1000L;

        salvarOtpComAliases(usuario, identity, email, otpHash, expiraEmMillis);

        // Envio assincrono pela cadeia de 3 tiers; resultado auditado via whenComplete.
        SmtpCliente.enviarRecuperacaoComResultado(usuario.getEmail(), otpCode, usuario.getDisplayName())
                .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                        usuario.getUserId(), "password_recovery_email", usuario.getEmail(), resultado, erro));
        repositorio.registrarAuditoria(usuario.getUserId(), "password_recovery_requested", usuario.getUserId(), null);

        AuthHttpUtils.aplicarLatenciaPadronizada(0L, false);

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", Integer.valueOf(200));
        resp.put("success", Boolean.TRUE);
        resp.put("expiresInSeconds", Integer.valueOf(ttlSegundos));
        resp.put("message", "Codigo de verificacao enviado para o e-mail cadastrado.");
        // maskedEmail para exibicao segura; email completo para o cliente pre-preencher a etapa verify.
        resp.put("maskedEmail", AuthHttpUtils.mascararEmail(usuario.getEmail()));
        resp.put("email", usuario.getEmail());
        resp.put("identity", usuario.getIdentity());
        if (!usuario.getDisplayName().isEmpty()) {
            resp.put("displayName", usuario.getDisplayName());
        }
        resp.put("profile", usuario.getProfile());
        if (!usuario.getDepartmentOrCourse().isEmpty()) {
            resp.put("departmentOrCourse", usuario.getDepartmentOrCourse());
        }
        enviarJson(resposta, 200, resp);
    }

    /**
     * Persiste o MESMO hash de OTP sob todas as chaves conhecidas da conta
     * (identidade canonica, identidade informada, e-mail informado, e-mail cadastrado).
     * Assim o verify funciona nao importa qual alias o usuario digitar na etapa 2.
     */
    private void salvarOtpComAliases(
            UsuarioAutenticado usuario, String identity, String email, String otpHash, long expiraEmMillis) {
        repositorio.salvarOtp(usuario.getIdentity(), otpHash, "RECOVERY", expiraEmMillis);
        if (identity != null && !identity.isEmpty() && !identity.equalsIgnoreCase(usuario.getIdentity())) {
            repositorio.salvarOtp(identity.toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }
        if (email != null && !email.isEmpty() && !email.equalsIgnoreCase(usuario.getIdentity())) {
            repositorio.salvarOtp(email.toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }
        if (!usuario.getEmail().equalsIgnoreCase(usuario.getIdentity())) {
            repositorio.salvarOtp(usuario.getEmail().toLowerCase(), otpHash, "RECOVERY", expiraEmMillis);
        }
    }

    /**
     * Etapa 2 - verify-recovery-otp: valida o OTP (tentativas/expiracao/codigo),
     * consome o OTP e emite o recovery token JWT de 15min. Junto, registra um GRANT
     * no banco indexado pelo SHA-256 do jti - e esse grant que torna o reset de uso
     * unico (o JWT sozinho nao tem como garantir single-use).
     */
    private void tratarVerificacaoOtp(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = lerJsonObjeto(requisicao);
        String identity = getString(corpo, "identity");
        String code = getString(corpo, "code");
        String perfilSolicitado = getPrimeiroTexto(corpo, "profile", "perfil");

        if (identity == null || identity.isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Campo 'identity' e obrigatorio.");
            return;
        }
        if (code == null || code.isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Campo 'code' e obrigatorio.");
            return;
        }

        String normalizedIdentity = identity.toLowerCase();
        Document otpDoc = localizarOtpRecuperacao(normalizedIdentity);
        if (otpDoc == null) {
            responderErro(resposta, 401, "invalid_or_expired_code", "Codigo de recuperacao expirado ou nao encontrado.");
            return;
        }
        if (OtpService.tentativasExcedidas(otpDoc.getInteger("tentativas", 0))) {
            repositorio.removerOtp(normalizedIdentity, "RECOVERY");
            responderErro(resposta, 429, "recovery_attempts_exceeded",
                    "Numero maximo de tentativas excedido. Solicite um novo codigo.");
            return;
        }
        Date expiresAt = otpDoc.getDate("expiresAt");
        if (expiresAt != null && expiresAt.getTime() < System.currentTimeMillis()) {
            repositorio.removerOtp(normalizedIdentity, "RECOVERY");
            responderErro(resposta, 401, "invalid_or_expired_code", "Codigo de recuperacao expirado.");
            return;
        }
        if (!OtpService.validar(code, otpDoc.getString("otpHash"), AuthHttpUtils.obterSegredoOtp())) {
            repositorio.incrementarTentativasOtp(normalizedIdentity, "RECOVERY");
            responderErro(resposta, 401, "invalid_or_expired_code", "Codigo de recuperacao invalido.");
            return;
        }

        UsuarioAutenticado usuario = repositorio.buscarPorIdentidade(normalizedIdentity);
        if (usuario == null) {
            usuario = repositorio.buscarPorEmail(normalizedIdentity);
        }
        if (usuario == null) {
            responderErro(resposta, 401, "invalid_or_expired_code", "Usuario nao encontrado.");
            return;
        }
        if (perfilSolicitado != null && !perfilSolicitado.isEmpty()
                && !perfisCompativeis(perfilSolicitado, usuario.getProfile())) {
            responderErro(resposta, 403, "invalid_user_type",
                    construirMensagemPerfilIncompativel(perfilSolicitado, usuario.getProfile()));
            return;
        }

        // Consome o OTP antes de emitir o token: o mesmo codigo nao verifica duas vezes.
        repositorio.removerOtp(normalizedIdentity, "RECOVERY");

        String recoveryToken = JwtGerador.gerarRecoveryToken(usuario);
        String jti = JwtGerador.extrairJti(recoveryToken);
        if (jti != null && !jti.isEmpty()) {
            // Grant = fingerprint do jti com TTL de 15min (900_000ms), casado com o exp do token.
            repositorio.emitirGrantRecuperacao(usuario.getIdentity(), OtpService.sha256Hex(jti),
                    System.currentTimeMillis() + 900_000L);
        }

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", Integer.valueOf(200));
        resp.put("valid", Boolean.TRUE);
        resp.put("resetToken", recoveryToken);
        resp.put("recoveryToken", recoveryToken);
        resp.put("expiresIn", Integer.valueOf(900));
        resp.put("identity", usuario.getIdentity());
        resp.put("displayName", usuario.getDisplayName());
        resp.put("email", usuario.getEmail());
        resp.put("profile", usuario.getProfile());
        resp.put("departmentOrCourse", usuario.getDepartmentOrCourse());
        resp.put("campus", usuario.getCampus());
        resp.put("semester", usuario.getSemester());
        resp.put("shift", usuario.getShift());
        enviarJson(resposta, 200, resp);
    }

    /**
     * Localiza o registro RECOVERY tolerando aliases: chave direta -> conta por e-mail
     * (usa a identidade canonica) -> conta por identidade (usa o e-mail cadastrado).
     */
    private Document localizarOtpRecuperacao(String normalizedIdentity) {
        Document otpDoc = repositorio.buscarOtp(normalizedIdentity, "RECOVERY");
        if (otpDoc != null) {
            return otpDoc;
        }
        UsuarioAutenticado porEmail = repositorio.buscarPorEmail(normalizedIdentity);
        if (porEmail != null) {
            otpDoc = repositorio.buscarOtp(porEmail.getIdentity(), "RECOVERY");
            if (otpDoc != null) return otpDoc;
        }
        UsuarioAutenticado porId = repositorio.buscarPorIdentidade(normalizedIdentity);
        if (porId != null && !porId.getEmail().isEmpty()) {
            return repositorio.buscarOtp(porId.getEmail().toLowerCase(), "RECOVERY");
        }
        return null;
    }

    /**
     * Etapa 3 - reset-password: valida o recovery token (type=recovery) e a politica
     * de senha, CONSOME o grant atomicamente (anti-replay: segundo uso falha), coloca
     * o jti na blacklist, atualiza a senha (nova sessionVersion) e revoga todas as
     * sessoes - tokens antigos morrem junto com a senha velha.
     */
    private void tratarRedefinicaoSenha(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        Map<String, Object> corpo = lerJsonObjeto(requisicao);
        String recoveryToken = getPrimeiroTexto(corpo, "resetToken", "recoveryToken");
        String novaSenha = getPrimeiroTexto(corpo, "newPassword", "novaSenha");

        if (recoveryToken == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'resetToken' (ou 'recoveryToken') e obrigatorio.");
            return;
        }
        if (novaSenha == null) {
            responderErro(resposta, 400, "invalid_request", "Campo 'newPassword' (ou 'novaSenha') e obrigatorio.");
            return;
        }

        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null) {
            responderErro(resposta, 500, "jwt_config_error", "Segredo JWT nao configurado.");
            return;
        }

        UsuarioAutenticado usuario;
        try {
            usuario = JwtAuthValidator.validarToken(recoveryToken, segredo, "recovery");
        } catch (SecurityException e) {
            responderErro(resposta, 401, "invalid_or_expired_code",
                    "Token de recuperacao invalido ou expirado: " + e.getMessage());
            return;
        }

        SenhaHasher.ResultadoValidacao validacao = SenhaHasher.validarComplexidade(novaSenha);
        if (!validacao.isValido()) {
            responderErro(resposta, 400, "invalid_request", validacao.getMensagem());
            return;
        }

        String jti = JwtGerador.extrairJti(recoveryToken);
        String jtiHash = (jti != null && !jti.isEmpty()) ? OtpService.sha256Hex(jti) : "";
        // Consumo atomico do grant: so UMA requisicao consegue trocar a senha com este token.
        if (jtiHash.isEmpty() || !repositorio.consumirGrantRecuperacao(jtiHash)) {
            responderErro(resposta, 401, "invalid_or_expired_code", "Token de recuperacao ja utilizado ou expirado.");
            return;
        }
        RevogacaoTokens.getInstance().revogar(jti, JwtGerador.extrairExpiracaoMillis(recoveryToken));

        boolean atualizado = repositorio.atualizarSenha(usuario.getUserId(), novaSenha);
        if (!atualizado) {
            responderErro(resposta, 500, "internal_error", "Falha ao atualizar senha.");
            return;
        }

        repositorio.revogarTodasSessoes(usuario.getUserId());
        repositorio.registrarAuditoria(usuario.getUserId(), "password_reset", usuario.getUserId(), null);

        Map<String, Object> resp = new LinkedHashMap<String, Object>();
        resp.put("status", Integer.valueOf(200));
        resp.put("success", Boolean.TRUE);
        resp.put("message", "Senha redefinida com sucesso. Realize login novamente.");
        enviarJson(resposta, 200, resp);
    }

    /** Normaliza perfis pt/en para o canonico do RBAC (student/discente->aluno, teacher/professor->docente...). */
    public static String normalizarPerfil(String perfil) {
        if (perfil == null) return "";
        String p = perfil.trim().toLowerCase();
        if ("student".equals(p) || "discente".equals(p)) return "aluno";
        if ("teacher".equals(p) || "professor".equals(p)) return "docente";
        if ("administrator".equals(p) || "administrador".equals(p)) return "admin";
        return p;
    }

    /** Compatibilidade de portal: perfil ausente em qualquer lado = sem restricao (true). */
    public static boolean perfisCompativeis(String perfilSolicitado, String perfilConta) {
        String s = normalizarPerfil(perfilSolicitado);
        String c = normalizarPerfil(perfilConta);
        if (s.isEmpty() || c.isEmpty()) return true;
        return s.equals(c);
    }

    /** Rotulo amigavel do perfil para mensagens de erro (Aluno/Docente/Admin). */
    public static String rotuloPerfil(String perfil) {
        String norm = normalizarPerfil(perfil);
        if ("aluno".equals(norm)) return "Aluno";
        if ("docente".equals(norm)) return "Docente";
        if ("admin".equals(norm)) return "Admin";
        return perfil != null && !perfil.trim().isEmpty() ? perfil.trim() : "Desconhecido";
    }

    /** Mensagem padrao de "portal errado", compartilhada com LoginHandler (403 invalid_user_type). */
    public static String construirMensagemPerfilIncompativel(String perfilSolicitado, String perfilConta) {
        return "Tipo de usuário inválido: esta conta pertence ao perfil de "
                + rotuloPerfil(perfilConta)
                + ", não ao perfil selecionado ("
                + rotuloPerfil(perfilSolicitado)
                + ").";
    }
}
