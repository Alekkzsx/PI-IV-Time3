// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import auth.model.UsuarioAutenticado;
import auth.modules.login.RefreshTokenHandler;
import auth.modules.login.TwoFactorHandler;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtGerador;
import auth.utils.OtpService;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

/**
 * Testes unitarios de ciclo de vida do repositorio nos handlers HTTP
 * (garante que TwoFactorHandler e RefreshTokenHandler nao fecham o pool singleton).
 */
public class HandlerLifecycleTeste {
    private static final String SEGREDO_TESTE = "segredo-institucional-teste-minimo-32-chars!";
    private static final String OTP_SEGREDO = "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890";
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    private static final class RepoSpy extends RepositorioUsuarios {
        boolean fechado = false;
        int sessoesCriadas = 0;
        final UsuarioAutenticado usuario = new UsuarioAutenticado(
                "507f1f77bcf86cd799439022",
                "docente",
                "",
                3,
                "prof.helena",
                "Profa. Helena",
                "helena@example.edu",
                true,
                "ES",
                "",
                "",
                "");
        Document otpAtivo;

        RepoSpy() {
            super(false);
            String hash = OtpService.hashOtp("123456", OTP_SEGREDO);
            otpAtivo = new Document("identity", "prof.helena")
                    .append("type", "2FA_LOGIN")
                    .append("otpHash", hash)
                    .append("tentativas", 0)
                    .append("expiresAt", new Date(System.currentTimeMillis() + 300_000L));
        }

        @Override
        public UsuarioAutenticado buscarPorIdentidade(String identidade) {
            return "prof.helena".equalsIgnoreCase(identidade) ? usuario : null;
        }

        @Override
        public UsuarioAutenticado buscarPorId(String userId) {
            return usuario.getUserId().equals(userId) ? usuario : null;
        }

        @Override
        public Document buscarOtp(String identity, String type) {
            if ("2FA_LOGIN".equals(type) && "prof.helena".equalsIgnoreCase(identity)) {
                return otpAtivo;
            }
            return null;
        }

        @Override
        public boolean consumirCodigoBackup(String userId, String codigo) { return false; }

        @Override
        public void incrementarTentativasOtp(String identity, String type) {}

        @Override
        public void removerOtp(String identity, String type) {
            if ("2FA_LOGIN".equals(type)) otpAtivo = null;
        }

        @Override
        public void criarSessao(String userId, String sessionId, long expiresAtMillis, String userAgent, String ipAddress) {
            sessoesCriadas++;
        }

        @Override
        public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details, String ipAddress) {}

        @Override
        public void fechar() {
            fechado = true;
        }
    }

    public static int executar() {
        falhas = 0;
        String anteriorJwt = System.getProperty("AUTH_JWT_SECRET");
        String anteriorOtp = System.getProperty("AUTH_OTP_SECRET");
        String anteriorLatency = System.getProperty("STANDARDIZED_AUTH_LATENCY_MS");
        try {
            System.setProperty("AUTH_JWT_SECRET", SEGREDO_TESTE);
            System.setProperty("AUTH_OTP_SECRET", OTP_SEGREDO);
            System.setProperty("STANDARDIZED_AUTH_LATENCY_MS", "0");

            RepoSpy repo = new RepoSpy();
            TwoFactorHandler twoFactorHandler = new TwoFactorHandler(repo);
            RefreshTokenHandler refreshHandler = new RefreshTokenHandler(repo);

            String resp2fa = postJson(twoFactorHandler, "/api/auth/verify-two-factor",
                    "{\"identity\":\"prof.helena\",\"code\":\"123456\"}");
            esperar(resp2fa.startsWith("HTTP/1.1 200")
                            && resp2fa.contains("\"accessToken\":")
                            && !repo.fechado
                            && repo.sessoesCriadas == 1,
                    "TwoFactorHandler: conclui 2FA, persiste sessao e preserva pool compartilhado aberto");

            String resp2faErro = postJson(twoFactorHandler, "/api/auth/verify-two-factor",
                    "{\"identity\":\"prof.helena\",\"code\":\"000000\"}");
            esperar(resp2faErro.startsWith("HTTP/1.1 401") && !repo.fechado,
                    "TwoFactorHandler: erro 401 tambem preserva pool compartilhado aberto");

            String refreshToken = JwtGerador.gerarRefreshToken(repo.usuario, 3);
            String respRefresh = postJson(refreshHandler, "/api/auth/refresh",
                    "{\"refreshToken\":\"" + refreshToken + "\"}");
            esperar(respRefresh.startsWith("HTTP/1.1 200")
                            && respRefresh.contains("\"refreshToken\":")
                            && !repo.fechado
                            && repo.sessoesCriadas == 2,
                    "RefreshTokenHandler: rotaciona tokens mantendo pool compartilhado aberto");

            String refreshDesatualizado = JwtGerador.gerarRefreshToken(repo.usuario, 1);
            String respRefreshVelho = postJson(refreshHandler, "/api/auth/refresh",
                    "{\"refreshToken\":\"" + refreshDesatualizado + "\"}");
            esperar(respRefreshVelho.startsWith("HTTP/1.1 401") && !repo.fechado,
                    "RefreshTokenHandler: rejeita sessionVersion divergente (401) sem fechar pool");
        } catch (Exception e) {
            esperar(false, "HandlerLifecycleTeste sem excecoes: " + e.getMessage());
        } finally {
            if (anteriorJwt == null) System.clearProperty("AUTH_JWT_SECRET");
            else System.setProperty("AUTH_JWT_SECRET", anteriorJwt);
            if (anteriorOtp == null) System.clearProperty("AUTH_OTP_SECRET");
            else System.setProperty("AUTH_OTP_SECRET", anteriorOtp);
            if (anteriorLatency == null) System.clearProperty("STANDARDIZED_AUTH_LATENCY_MS");
            else System.setProperty("STANDARDIZED_AUTH_LATENCY_MS", anteriorLatency);
        }
        return falhas;
    }

    private static String postJson(core.ManipuladorHttp handler, String path, String jsonBody) throws Exception {
        byte[] bytes = jsonBody.getBytes(StandardCharsets.UTF_8);
        String raw = "POST " + path + " HTTP/1.1\r\n"
                + "Host: localhost\r\n"
                + "Content-Type: application/json\r\n"
                + "Content-Length: " + bytes.length + "\r\n\r\n"
                + jsonBody;
        RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(raw.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        RespostaHttp resp = new RespostaHttp(out);
        handler.handle(req, resp);
        return new String(out.toByteArray(), StandardCharsets.UTF_8);
    }
}
