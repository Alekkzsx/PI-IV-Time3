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
import java.util.concurrent.TimeUnit;

/**
 * Endpoint de login institucional com defesa em profundidade.
 * Rota: POST /api/auth/login
 *
 * Body: { "identidade": "string", "senha": "string" }
 *
 * Fluxo de autenticacao:
 * 1. Rate limiting: verifica se a identidade/IP nao esta bloqueada
 * 2. Autenticacao PBKDF2 com dummy hash (protecao contra enumeracao)
 * 3. Se 2FA ativado: retorna desafio OTP em vez de tokens
 * 4. Gera par de tokens (access + refresh)
 * 5. Persiste sessao no MongoDB
 * 6. Reseta contador de falhas no rate limiter
 *
 * Response 200: { "token": "...", "refreshToken": "...", "usuario": {...} }
 * Response 202: { "twoFactorRequired": true, "identity": "..." } (quando 2FA ativo)
 * Response 401: { "erro": "...", "tentativas": N, "maximo": N }
 * Response 429: { "erro": "...", "retryAfter": segundos } (bloqueado)
 */
public class LoginHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public LoginHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio;
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);
        aplicarHeadersSeguranca(resposta);

        // Aceitar OPTIONS para pre-flight CORS
        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST para login.");
            return;
        }

        long inicioProcessamento = System.currentTimeMillis();

        try {
            // Parsear body JSON
            Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
            if (corpo == null) {
                corpo = new LinkedHashMap<String, Object>();
            }

            String identidade = getString(corpo, "identidade");
            if (identidade == null || identidade.trim().isEmpty()) {
                identidade = getString(corpo, "identity");
            }
            String senha = getString(corpo, "senha");
            if (senha == null || senha.trim().isEmpty()) {
                senha = getString(corpo, "password");
            }
            String perfilSolicitado = getString(corpo, "profile");
            if (perfilSolicitado == null || perfilSolicitado.trim().isEmpty()) {
                perfilSolicitado = getString(corpo, "perfil");
            }
            String ipCliente = extrairIpCliente(requisicao);

            // Validar campos obrigatorios
            if (identidade == null || identidade.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'identidade' (ou 'identity') e obrigatorio.");
                return;
            }
            if (senha == null || senha.trim().isEmpty()) {
                enviarErro(resposta, 400, "Campo 'senha' (ou 'password') e obrigatorio.");
                return;
            }

            // 1. Rate limiting: verificar bloqueio
            LimitadorTentativas limitador = LimitadorTentativas.getInstance();
            if (!limitador.permitirTentativa(identidade, ipCliente)) {
                long segundosRestantes = limitador.segundosRestantesBloqueio(identidade);
                resposta.adicionarCabecalho("Retry-After", String.valueOf(segundosRestantes));
                String msgBloqueio = "Muitas tentativas de login. Tente novamente em " + segundosRestantes + " segundos.";
                Map<String, Object> erro = new LinkedHashMap<String, Object>();
                erro.put("status", 429);
                erro.put("code", "too_many_attempts");
                erro.put("erro", msgBloqueio);
                erro.put("message", msgBloqueio);
                erro.put("retryAfter", segundosRestantes);
                resposta.enviarJson(429, Json.escrever(erro));
                return;
            }

            // 2. Autenticar contra MongoDB (com dummy hash para usuarios inexistentes)
            UsuarioAutenticado usuario = repositorio.autenticar(identidade, senha);

            if (usuario == null) {
                // Registrar falha no rate limiter
                String mensagem = limitador.registrarFalha(identidade, ipCliente);
                Map<String, Object> det = new LinkedHashMap<String, Object>();
                det.put("identity", identidade);
                det.put("reason", "invalid_credentials");
                repositorio.registrarAuditoria("anonymous", "login_failed", identidade, det, ipCliente);

                // Latencia padronizada contra timing attacks
                aplicarLatenciaPadronizada(inicioProcessamento);

                Map<String, Object> erro = new LinkedHashMap<String, Object>();
                erro.put("status", 401);
                erro.put("code", "invalid_credentials");
                erro.put("erro", mensagem);
                erro.put("message", mensagem);
                int maxTentativas = utils.ConfigEnv.obterInteiro("MAX_FAILED_LOGIN_ATTEMPTS", 5);
                erro.put("maximo", maxTentativas);
                resposta.enviarJson(401, Json.escrever(erro));
                return;
            }

            if (perfilSolicitado != null && !perfilSolicitado.trim().isEmpty()
                    && !perfilSolicitado.trim().equalsIgnoreCase(usuario.getProfile())) {
                limitador.registrarFalha(identidade, ipCliente);
                Map<String, Object> det = new LinkedHashMap<String, Object>();
                det.put("requestedProfile", perfilSolicitado.trim());
                det.put("actualProfile", usuario.getProfile());
                repositorio.registrarAuditoria(usuario.getUserId(), "login_failed", usuario.getUserId(), det, ipCliente);
                aplicarLatenciaPadronizada(inicioProcessamento);
                String msgPerfil = "Credenciais invalidas para o perfil selecionado.";
                Map<String, Object> erro = new LinkedHashMap<String, Object>();
                erro.put("status", 401);
                erro.put("code", "invalid_profile");
                erro.put("erro", msgPerfil);
                erro.put("message", msgPerfil);
                resposta.enviarJson(401, Json.escrever(erro));
                return;
            }

            // 3. Verificar se 2FA esta ativado
            if (usuario.isTwoFactorEnabled()) {
                aplicarLatenciaPadronizada(inicioProcessamento);

                // Gerar desafio OTP para 2FA
                String otpCode = OtpService.gerarCodigo();
                String otpSecret = utils.ConfigEnv.obter("AUTH_OTP_SECRET",
                        "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890");
                String otpHash = OtpService.hashOtp(otpCode, otpSecret);
                String challengeToken = java.util.UUID.randomUUID().toString().replace("-", "")
                        + java.util.UUID.randomUUID().toString().replace("-", "");

                long ttlOtp = (long) utils.ConfigEnv.obterInteiro("AUTH_OTP_TTL_SECONDS", 300) * 1000L;
                long expiraMillis = System.currentTimeMillis() + ttlOtp;
                repositorio.salvarOtp(usuario.getIdentity(), otpHash, "2FA_LOGIN", expiraMillis);
                repositorio.salvarOtp(challengeToken, usuario.getIdentity(), "2FA_CHALLENGE", expiraMillis);

                // Enviar OTP por email apenas se houver e-mail valido cadastrado
                if (SmtpCliente.isEmailValido(usuario.getEmail())) {
                    SmtpCliente.enviarOtpComResultado(usuario.getEmail(), otpCode, usuario.getDisplayName())
                            .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                                    usuario.getUserId(), "login_2fa_email", usuario.getEmail(), resultado, erro));
                } else {
                    repositorio.registrarAuditoria(usuario.getUserId(), "login_2fa_missing_email", usuario.getUserId(), null, ipCliente);
                }

                Map<String, Object> desafio = new LinkedHashMap<String, Object>();
                desafio.put("status", 202);
                desafio.put("success", true);
                desafio.put("requiresTwoFactor", true);
                desafio.put("twoFactorRequired", true);
                desafio.put("challengeToken", challengeToken);
                desafio.put("identity", usuario.getIdentity());
                desafio.put("email", mascararEmail(usuario.getEmail()));
                desafio.put("expiresIn", utils.ConfigEnv.obterInteiro("AUTH_OTP_TTL_SECONDS", 300));
                resposta.enviarJson(202, Json.escrever(desafio));
                return;
            }

            // 4. Gerar par de tokens (access + refresh)
            UsuarioAutenticado usuarioFinal = repositorio.buscarPorId(usuario.getUserId());
            int sessionVersion = usuarioFinal != null ? usuarioFinal.getSessionVersion() : usuario.getSessionVersion();
            UsuarioAutenticado usuarioParaResposta = usuarioFinal != null ? usuarioFinal : usuario;

            JwtGerador.ParTokens parTokens = JwtGerador.gerarParTokens(usuario, sessionVersion);

            // 5. Persistir sessao no MongoDB
            long expiraAccessMillis = JwtGerador.extrairExpiracaoMillis(parTokens.getAccessToken());
            String jtiAccess = JwtGerador.extrairJti(parTokens.getAccessToken());
            String userAgent = requisicao.getCabecalho("user-agent");
            if (jtiAccess != null) {
                repositorio.criarSessao(usuario.getUserId(), jtiAccess, expiraAccessMillis, userAgent, ipCliente);
            }

            // 6. Reseta contador de falhas no rate limiter e audita login
            limitador.registrarSucesso(identidade, ipCliente);
            Map<String, Object> detSucesso = new LinkedHashMap<String, Object>();
            detSucesso.put("profile", usuarioParaResposta.getProfile());
            repositorio.registrarAuditoria(usuarioParaResposta.getUserId(), "login_succeeded",
                    usuarioParaResposta.getUserId(), detSucesso, ipCliente);

            // Construir resposta de sucesso com dados reais do MongoDB
            Map<String, Object> payloadUsuario = new LinkedHashMap<String, Object>();
            payloadUsuario.put("id", usuarioParaResposta.getUserId());
            payloadUsuario.put("identidade", usuarioParaResposta.getIdentity());
            payloadUsuario.put("identity", usuarioParaResposta.getIdentity());
            payloadUsuario.put("perfil", usuarioParaResposta.getProfile());
            payloadUsuario.put("profile", usuarioParaResposta.getProfile());
            if (!usuarioParaResposta.getDisplayName().isEmpty()) {
                payloadUsuario.put("nome", usuarioParaResposta.getDisplayName());
                payloadUsuario.put("displayName", usuarioParaResposta.getDisplayName());
            }
            if (!usuarioParaResposta.getEmail().isEmpty()) {
                payloadUsuario.put("email", usuarioParaResposta.getEmail());
            }
            if (!usuarioParaResposta.getDepartmentOrCourse().isEmpty()) {
                payloadUsuario.put("departmentOrCourse", usuarioParaResposta.getDepartmentOrCourse());
                payloadUsuario.put("department", usuarioParaResposta.getDepartmentOrCourse());
            }
            if (!usuarioParaResposta.getCampus().isEmpty()) {
                payloadUsuario.put("campus", usuarioParaResposta.getCampus());
            }
            if (!usuarioParaResposta.getSemester().isEmpty()) {
                payloadUsuario.put("semester", usuarioParaResposta.getSemester());
            }
            if (!usuarioParaResposta.getShift().isEmpty()) {
                payloadUsuario.put("shift", usuarioParaResposta.getShift());
            }
            payloadUsuario.put("twoFactorRequired", usuarioParaResposta.isTwoFactorEnabled());
            payloadUsuario.put("requirePasswordChange", usuarioParaResposta.isRequirePasswordChange());

            Map<String, Object> respostaSucesso = new LinkedHashMap<String, Object>();
            respostaSucesso.put("status", 200);
            respostaSucesso.put("success", true);
            respostaSucesso.put("accessToken", parTokens.getAccessToken());
            respostaSucesso.put("token", parTokens.getAccessToken());
            respostaSucesso.put("refreshToken", parTokens.getRefreshToken());
            respostaSucesso.put("usuario", payloadUsuario);
            respostaSucesso.put("user", payloadUsuario);

            aplicarLatenciaPadronizada(inicioProcessamento);

            resposta.enviarJson(200, Json.escrever(respostaSucesso));

        } catch (DatabaseUnavailableException e) {
            HttpUtils.enviarErroJson(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (IllegalArgumentException e) {
            enviarErro(resposta, 400, "Corpo da requisicao invalido: " + e.getMessage());
        } catch (SecurityException e) {
            enviarErro(resposta, 401, e.getMessage());
        } catch (Exception e) {
            System.err.println("[LOGIN] Erro inesperado: " + e.getMessage());
            e.printStackTrace();
            enviarErro(resposta, 500, "Erro interno no servidor.");
        }
    }

    private String getString(Map<String, Object> mapa, String chave) {
        Object valor = mapa.get(chave);
        if (valor instanceof String) {
            return ((String) valor).trim();
        }
        return null;
    }

    /**
     * Extrai o IP do cliente, respeitando X-Forwarded-For e X-Real-IP.
     */
    private String extrairIpCliente(RequisicaoHttp requisicao) {
        String forwarded = requisicao.getCabecalho("x-forwarded-for");
        if (forwarded != null && !forwarded.trim().isEmpty()) {
            // Pegar o primeiro IP da lista (cliente real)
            int virgula = forwarded.indexOf(',');
            return virgula > 0 ? forwarded.substring(0, virgula).trim() : forwarded.trim();
        }
        String realIp = requisicao.getCabecalho("x-real-ip");
        if (realIp != null && !realIp.trim().isEmpty()) {
            return realIp.trim();
        }
        return "unknown";
    }

    /**
     * Mascara o email para exibir apenas o dominio (ex: "a***b@gmail.com").
     */
    private String mascararEmail(String email) {
        if (email == null || email.isEmpty()) return "";
        int arroba = email.indexOf('@');
        if (arroba <= 1) return email;
        return email.charAt(0) + "***" + email.substring(arroba - 1);
    }

    /**
     * Aplica latencia padronizada para mitigar ataques de temporizacao.
     * Leitura do .env: STANDARDIZED_AUTH_LATENCY_MS (padrao: 1000ms).
     */
    private void aplicarLatenciaPadronizada(long inicioProcessamento) {
        long latenciaAlvo = utils.ConfigEnv.obterInteiro("STANDARDIZED_AUTH_LATENCY_MS", 1000);
        long jitter = utils.ConfigEnv.obterInteiro("STANDARDIZED_AUTH_JITTER_MS", 25);
        long decorrido = System.currentTimeMillis() - inicioProcessamento;
        long restante = latenciaAlvo - decorrido;

        if (restante > 0) {
            try {
                // Adicionar jitter aleatorio
                long jitterReal = (long) (Math.random() * jitter * 2) - jitter;
                Thread.sleep(Math.max(0, restante + jitterReal));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }

    private void aplicarHeadersSeguranca(RespostaHttp resposta) {
        resposta.adicionarCabecalho("Cache-Control", "no-store");
        resposta.adicionarCabecalho("Pragma", "no-cache");
        resposta.adicionarCabecalho("X-Content-Type-Options", "nosniff");
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("code", status == 401 ? "unauthorized" : status == 400 ? "invalid_request" : "error");
        erro.put("message", mensagem);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
