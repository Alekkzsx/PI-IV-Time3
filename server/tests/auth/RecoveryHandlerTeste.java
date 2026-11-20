// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import auth.model.UsuarioAutenticado;
import auth.modules.conta.RecoveryHandler;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.OtpService;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;
import utils.Json;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Testes unitarios do RecoveryHandler (emissao e consumo single-use do resetToken sem replay).
 */
public class RecoveryHandlerTeste {
    private static final String SEGREDO_TESTE = "segredo-institucional-teste-minimo-32-chars!";
    private static final String OTP_SEGREDO = "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890";
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    private static final class RepoResetFake extends RepositorioUsuarios {
        final Set<String> grantsDisponiveis = new HashSet<String>();
        final Map<String, String> senhasAtualizadas = new HashMap<String, String>();
        final Map<String, String> otpsSalvos = new HashMap<String, String>();
        final java.util.List<String> auditorias = new java.util.ArrayList<String>();
        int sessoesRevogadas = 0;
        Document otpRecuperacao;

        final UsuarioAutenticado usuario = new UsuarioAutenticado(
                "507f1f77bcf86cd799439011",
                "aluno",
                "",
                1,
                "2024.1.00001",
                "Aluno Teste",
                "aluno@example.edu",
                false,
                "ES",
                "",
                "",
                "");

        RepoResetFake() {
            super(false);
        }

        void prepararOtp(String codigo) {
            otpRecuperacao = new Document("identity", "2024.1.00001")
                    .append("type", "RECOVERY")
                    .append("otpHash", OtpService.hashOtp(codigo, OTP_SEGREDO))
                    .append("tentativas", 0)
                    .append("expiresAt", new Date(System.currentTimeMillis() + 300_000L));
        }

        @Override
        public UsuarioAutenticado buscarPorIdentidade(String identidade) {
            if ("2024.1.00001".equalsIgnoreCase(identidade) || "aluno@example.edu".equalsIgnoreCase(identidade)) {
                return usuario;
            }
            return null;
        }

        @Override
        public UsuarioAutenticado buscarPorEmail(String email) {
            return "aluno@example.edu".equalsIgnoreCase(email) ? usuario : null;
        }

        @Override
        public void salvarOtp(String identity, String otpHash, String type, long expiresAtMillis) {
            otpsSalvos.put(identity + ":" + type, otpHash);
        }

        @Override
        public Document buscarOtp(String identity, String type) {
            if ("RECOVERY".equals(type) && "2024.1.00001".equalsIgnoreCase(identity)) {
                return otpRecuperacao;
            }
            return null;
        }

        @Override
        public void removerOtp(String identity, String type) {
            if ("RECOVERY".equals(type)) otpRecuperacao = null;
        }

        @Override
        public void incrementarTentativasOtp(String identity, String type) {}

        @Override
        public void emitirGrantRecuperacao(String normalizedIdentity, String jtiHash, long expiresAtMillis) {
            grantsDisponiveis.add(jtiHash);
        }

        @Override
        public boolean consumirGrantRecuperacao(String jtiHash) {
            return grantsDisponiveis.remove(jtiHash);
        }

        @Override
        public boolean atualizarSenha(String userId, String novaSenha) {
            senhasAtualizadas.put(userId, novaSenha);
            return true;
        }

        @Override
        public void revogarTodasSessoes(String userId) {
            sessoesRevogadas++;
        }

        @Override
        public void registrarAuditoria(String actorId, String action, String target, Map<String, Object> details) {
            auditorias.add(action + ":" + target);
        }
    }

    public static int executar() {
        falhas = 0;
        String anteriorJwt = System.getProperty("AUTH_JWT_SECRET");
        String anteriorOtp = System.getProperty("AUTH_OTP_SECRET");
        String anteriorMinLen = System.getProperty("PASSWORD_MIN_LENGTH");
        String anteriorSandbox = System.getProperty("SMTP_SANDBOX_MODE");
        String anteriorLatencia = System.getProperty("STANDARDIZED_AUTH_LATENCY_MS");
        try {
            System.setProperty("AUTH_JWT_SECRET", SEGREDO_TESTE);
            System.setProperty("AUTH_OTP_SECRET", OTP_SEGREDO);
            System.setProperty("PASSWORD_MIN_LENGTH", "8");
            System.setProperty("SMTP_SANDBOX_MODE", "true");
            System.setProperty("STANDARDIZED_AUTH_LATENCY_MS", "0");

            RepoResetFake repo = new RepoResetFake();
            RecoveryHandler handler = new RecoveryHandler(repo);

            // 0A. Payload vazio retorna 400 invalid_request
            String respVazio = postJson(handler, "/api/auth/send-recovery-otp", "{}");
            esperar(respVazio.startsWith("HTTP/1.1 400") && repo.otpsSalvos.isEmpty(),
                    "RecoveryHandler: payload vazio rejeita com 400 sem gerar OTP");

            // 0B. E-mail nao cadastrado no banco retorna 404 email_not_registered e nao gera OTP
            String respNaoCadastrado = postJson(handler, "/api/auth/send-recovery-otp",
                    "{\"email\":\"desconhecido@gmail.com\"}");
            esperar(respNaoCadastrado.startsWith("HTTP/1.1 404")
                            && respNaoCadastrado.contains("email_not_registered")
                            && repo.otpsSalvos.isEmpty()
                            && repo.auditorias.contains("password_recovery_not_registered:desconhecido@gmail.com"),
                    "RecoveryHandler: e-mail nao cadastrado retorna 404 explicito e nao envia OTP");

            // 0B.1. E-mail de aluno com perfil 'admin' selecionado retorna 403 invalid_user_type e nao gera OTP
            String respPerfilInvalido = postJson(handler, "/api/auth/send-recovery-otp",
                    "{\"identity\":\"ALUNO@example.edu\",\"profile\":\"admin\"}");
            esperar(respPerfilInvalido.startsWith("HTTP/1.1 403")
                            && respPerfilInvalido.contains("invalid_user_type")
                            && respPerfilInvalido.contains("Tipo de usu")
                            && repo.otpsSalvos.isEmpty()
                            && repo.auditorias.contains("password_recovery_invalid_profile:507f1f77bcf86cd799439011"),
                    "RecoveryHandler: e-mail de aluno sob perfil admin rejeita com 403 invalid_user_type sem gerar OTP");

            // 0C. E-mail cadastrado com perfil compativel gera OTP, audita e retorna 200 com maskedEmail
            String respCadastrado = postJson(handler, "/api/auth/send-recovery-otp",
                    "{\"email\":\"ALUNO@example.edu\",\"profile\":\"aluno\"}");
            Thread.sleep(150);
            esperar(respCadastrado.startsWith("HTTP/1.1 200")
                            && respCadastrado.contains("maskedEmail")
                            && repo.otpsSalvos.containsKey("2024.1.00001:RECOVERY")
                            && repo.otpsSalvos.containsKey("aluno@example.edu:RECOVERY")
                            && repo.auditorias.contains("password_recovery_requested:507f1f77bcf86cd799439011"),
                    "RecoveryHandler: e-mail cadastrado gera OTP e retorna 200");

            // 1. Verificar OTP gera resetToken e emite grant unico
            repo.prepararOtp("654321");
            String respVerify = postJson(handler, "/api/auth/verify-recovery-otp",
                    "{\"identity\":\"2024.1.00001\",\"code\":\"654321\"}");
            String resetToken = extrairResetToken(respVerify);
            esperar(respVerify.startsWith("HTTP/1.1 200")
                            && resetToken != null
                            && repo.grantsDisponiveis.size() == 1,
                    "RecoveryHandler: verify-recovery-otp emite resetToken e persiste grant de uso unico (200)");

            // 2. Senha invalida (< 8 chars) retorna 400 sem consumir o grant antes da validacao
            String respFraca = postJson(handler, "/api/auth/reset-password",
                    "{\"resetToken\":\"" + resetToken + "\",\"newPassword\":\"ab\"}");
            esperar(respFraca.startsWith("HTTP/1.1 400") && repo.grantsDisponiveis.size() == 1,
                    "RecoveryHandler: senha curta retorna 400 mantendo grant ainda disponivel");

            // 3. Primeiro uso valido redefine senha, revoga sessoes e consome grant
            String corpoReset = "{\"resetToken\":\"" + resetToken + "\",\"newPassword\":\"NovaSenha@2026\"}";
            String primeira = postJson(handler, "/api/auth/reset-password", corpoReset);
            esperar(primeira.startsWith("HTTP/1.1 200")
                            && "NovaSenha@2026".equals(repo.senhasAtualizadas.get("507f1f77bcf86cd799439011"))
                            && repo.sessoesRevogadas == 1
                            && repo.grantsDisponiveis.isEmpty(),
                    "RecoveryHandler: primeiro uso de resetToken redefine senha e consome grant (200)");

            // 4. Segunda tentativa com o mesmo resetToken falha com 401 (anti-replay)
            String segundaReplay = postJson(handler, "/api/auth/reset-password", corpoReset);
            esperar(segundaReplay.startsWith("HTTP/1.1 401"),
                    "RecoveryHandler: segunda tentativa com mesmo resetToken sofre bloqueio anti-replay (401)");
        } catch (Exception e) {
            esperar(false, "RecoveryHandlerTeste sem excecoes: " + e.getMessage());
        } finally {
            restaurar("AUTH_JWT_SECRET", anteriorJwt);
            restaurar("AUTH_OTP_SECRET", anteriorOtp);
            restaurar("PASSWORD_MIN_LENGTH", anteriorMinLen);
            restaurar("SMTP_SANDBOX_MODE", anteriorSandbox);
            restaurar("STANDARDIZED_AUTH_LATENCY_MS", anteriorLatencia);
        }
        return falhas;
    }

    private static void restaurar(String chave, String anterior) {
        if (anterior == null) System.clearProperty(chave);
        else System.setProperty(chave, anterior);
    }

    private static String extrairResetToken(String httpResp) {
        int sep = httpResp.indexOf("\r\n\r\n");
        if (sep < 0) return null;
        String json = httpResp.substring(sep + 4);
        Map<String, Object> parsed = Json.analisarObjeto(json);
        if (parsed == null) return null;
        Object token = parsed.get("resetToken");
        return token instanceof String ? (String) token : null;
    }

    private static String postJson(RecoveryHandler handler, String path, String jsonBody) throws Exception {
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
