// Desenvolvido por Time 3 AGMRM — PI-IV (PUC-Campinas 2026)
// Equipe: Alex Gabriel (24802449), Guilherme Moreira (25006702),
//         Marcelo Zarpelon (25015323), Murillo Caravita (25014012), Rafael Inacio (25009719)

import auth.model.UsuarioAutenticado;
import auth.modules.login.LoginHandler;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.JwtAuthValidator;
import auth.utils.JwtGerador;
import auth.utils.LimitadorTentativas;
import auth.utils.SenhaHasher;
import bridge.ClientePonteAcademica;
import core.MonitorBackendAcademico;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import utils.Json;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Teste Unitario INTERCLASSE em JUnit 5 — Servico Principal do Servidor Java:
 * {@link LoginHandler} (POST /api/auth/login).
 */
@DisplayName("Interclasse — Servico Principal LoginHandler (POST /api/auth/login)")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class InterclasseLoginServiceTest {

    private static final String JWT_SECRET_TESTE = "agmrm-junit5-interclasse-secret-key-2026-puc-campinas";

    private static String prevJwtSecret;
    private static String prevLatencyMs;
    private static String prevMaxAttempts;
    private static String prevLockoutSec;

    private RepositorioUsuariosStub repositorio;
    private LoginHandler loginHandler;

    @BeforeAll
    static void configurarAmbienteTeste() {
        prevJwtSecret = System.getProperty("AUTH_JWT_SECRET");
        prevLatencyMs = System.getProperty("STANDARDIZED_AUTH_LATENCY_MS");
        prevMaxAttempts = System.getProperty("MAX_FAILED_LOGIN_ATTEMPTS");
        prevLockoutSec = System.getProperty("LOCKOUT_DURATION_SECONDS");

        System.setProperty("AUTH_JWT_SECRET", JWT_SECRET_TESTE);
        System.setProperty("STANDARDIZED_AUTH_LATENCY_MS", "0");
        System.setProperty("MAX_FAILED_LOGIN_ATTEMPTS", "5");
        System.setProperty("LOCKOUT_DURATION_SECONDS", "30");
    }

    @AfterAll
    static void restaurarAmbiente() {
        MonitorBackendAcademico.desativar();
        restaurar("AUTH_JWT_SECRET", prevJwtSecret);
        restaurar("STANDARDIZED_AUTH_LATENCY_MS", prevLatencyMs);
        restaurar("MAX_FAILED_LOGIN_ATTEMPTS", prevMaxAttempts);
        restaurar("LOCKOUT_DURATION_SECONDS", prevLockoutSec);
    }

    private static void restaurar(String chave, String valor) {
        if (valor == null) {
            System.clearProperty(chave);
        } else {
            System.setProperty(chave, valor);
        }
    }

    @BeforeEach
    void prepararCenario() {
        MonitorBackendAcademico.desativar();
        LimitadorTentativas.getInstance().limparTudo();

        String hashReal = SenhaHasher.hash("Agmrm@2026!");
        UsuarioAutenticado alunoCadastrado = new UsuarioAutenticado(
                "65f9a1b2c3d4e5f600000001",
                "aluno",
                "",
                3,
                "24802449",
                "Alex Gabriel Soares Sousa",
                "alex.sousa@puccampinas.edu.br",
                false,
                "Engenharia de Software",
                "Campus I",
                "4o Semestre",
                "Matutino"
        );
        repositorio = new RepositorioUsuariosStub(alunoCadastrado, hashReal);
        loginHandler = new LoginHandler(repositorio);
    }

    @Test
    @Order(1)
    @DisplayName("Cenario NORMAL: Login valido percorre pipeline completo, emite JWT HS256, persiste sessao e audita")
    void cenarioNormalAutenticacaoCompletaEValidacaoSessao() throws IOException {
        String corpoJson = "{\"identidade\":\"24802449\",\"senha\":\"Agmrm@2026!\",\"profile\":\"aluno\"}";
        RequisicaoHttp requisicao = criarRequisicaoHttp(
                "POST",
                "/api/auth/login",
                corpoJson,
                "Origin: http://localhost:3000\r\n"
                        + "User-Agent: FlutterWeb-AGMRM/3.0\r\n"
                        + "X-Forwarded-For: 189.40.12.77\r\n"
        );
        ByteArrayOutputStream bufferSaida = new ByteArrayOutputStream();
        RespostaHttp resposta = new RespostaHttp(bufferSaida);

        loginHandler.handle(requisicao, resposta);

        assertTrue(resposta.foiEnviada(), "Resposta deve ter sido serializada no OutputStream");
        String httpCru = new String(bufferSaida.toByteArray(), StandardCharsets.UTF_8);
        assertTrue(httpCru.startsWith("HTTP/1.1 200 OK\r\n"), "Status HTTP deve ser 200 OK");
        assertTrue(httpCru.contains("Cache-Control: no-store"), "Headers de seguranca de auth devem estar presentes");
        assertTrue(httpCru.contains("X-Content-Type-Options: nosniff"), "Header defensivo nosniff obrigatorio");

        Map<String, Object> payload = extrairCorpoJson(httpCru);
        assertEquals(Boolean.TRUE, payload.get("success"));
        assertNotNull(payload.get("accessToken"));
        assertNotNull(payload.get("refreshToken"));
        assertEquals(payload.get("accessToken"), payload.get("token"), "Alias legado token == accessToken");

        String accessToken = (String) payload.get("accessToken");
        String refreshToken = (String) payload.get("refreshToken");

        UsuarioAutenticado claimsAccess = JwtAuthValidator.validarToken(accessToken, JWT_SECRET_TESTE, "access");
        assertEquals("65f9a1b2c3d4e5f600000001", claimsAccess.getUserId());
        assertEquals("aluno", claimsAccess.getProfile());
        assertEquals(3, claimsAccess.getSessionVersion());
        assertFalse(claimsAccess.getSessionId().isEmpty(), "jti da sessao deve estar preenchido");

        UsuarioAutenticado claimsRefresh = JwtAuthValidator.validarToken(refreshToken, JWT_SECRET_TESTE, "refresh");
        assertEquals("65f9a1b2c3d4e5f600000001", claimsRefresh.getUserId());

        assertTrue(repositorio.sessaoAtiva(claimsAccess.getSessionId()),
                "Sessao deve estar persistida no repositorio com o mesmo jti do accessToken");
        assertEquals("189.40.12.77", repositorio.ultimoIpSessao, "IP extraido via RedeUtils deve constar na sessao");
        assertTrue(repositorio.eventosAuditoria.contains("login_succeeded"),
                "Evento login_succeeded deve ser auditado");

        RequisicaoHttp reqProtegida = criarRequisicaoHttp(
                "GET", "/api/auth/me", "", "Authorization: Bearer " + accessToken + "\r\n");
        UsuarioAutenticado validado = JwtAuthValidator.autenticarObrigatorio(reqProtegida, repositorio, false);
        assertEquals("24802449", validado.getIdentity());
        assertEquals("Engenharia de Software", validado.getDepartmentOrCourse());
    }

    @Test
    @Order(2)
    @DisplayName("Cenario ERRO: Rejeita perfil incompativel (403), aplica lockout (429), fail-closed (503) e lanca excecoes")
    void cenarioAlternativoErroPerfilLockoutFailClosedEThrows() throws IOException {
        String ip = "198.51.100.42";

        // Etapa A: Perfil incompativel -> HTTP 403
        RequisicaoHttp reqPerfilErrado = criarRequisicaoHttp(
                "POST", "/api/auth/login",
                "{\"identidade\":\"24802449\",\"senha\":\"Agmrm@2026!\",\"profile\":\"docente\"}",
                "X-Forwarded-For: " + ip + "\r\n"
        );
        ByteArrayOutputStream out403 = new ByteArrayOutputStream();
        loginHandler.handle(reqPerfilErrado, new RespostaHttp(out403));

        String http403 = new String(out403.toByteArray(), StandardCharsets.UTF_8);
        assertTrue(http403.startsWith("HTTP/1.1 403 Forbidden\r\n"));
        assertEquals("invalid_user_type", extrairCorpoJson(http403).get("code"));
        assertTrue(repositorio.eventosAuditoria.contains("login_failed"));

        // Etapa B: 4 falhas (401) -> Lockout (429 + Retry-After)
        for (int i = 0; i < 4; i++) {
            RequisicaoHttp reqSenhaErrada = criarRequisicaoHttp(
                    "POST", "/api/auth/login",
                    "{\"identidade\":\"24802449\",\"senha\":\"SenhaErrada!\",\"profile\":\"aluno\"}",
                    "X-Forwarded-For: " + ip + "\r\n"
            );
            ByteArrayOutputStream out401 = new ByteArrayOutputStream();
            loginHandler.handle(reqSenhaErrada, new RespostaHttp(out401));
            String http401 = new String(out401.toByteArray(), StandardCharsets.UTF_8);
            assertTrue(http401.startsWith("HTTP/1.1 401 Unauthorized\r\n"));
            assertEquals("invalid_credentials", extrairCorpoJson(http401).get("code"));
        }

        RequisicaoHttp reqBloqueada = criarRequisicaoHttp(
                "POST", "/api/auth/login",
                "{\"identidade\":\"24802449\",\"senha\":\"Agmrm@2026!\",\"profile\":\"aluno\"}",
                "X-Forwarded-For: " + ip + "\r\n"
        );
        ByteArrayOutputStream out429 = new ByteArrayOutputStream();
        loginHandler.handle(reqBloqueada, new RespostaHttp(out429));
        String http429 = new String(out429.toByteArray(), StandardCharsets.UTF_8);
        assertTrue(http429.startsWith("HTTP/1.1 429 Too Many Requests\r\n"));
        assertTrue(http429.contains("Retry-After:"));
        assertEquals("too_many_attempts", extrairCorpoJson(http429).get("code"));

        // Etapa C: Fail-Closed -> throws ExcecaoPonteAcademica -> HTTP 503
        MonitorBackendAcademico.configurar(true, "http://127.0.0.1:1");
        ClientePonteAcademica.ExcecaoPonteAcademica ex503 = assertThrows(
                ClientePonteAcademica.ExcecaoPonteAcademica.class,
                MonitorBackendAcademico::garantirOnlineSeAtivo
        );
        assertEquals(503, ex503.getStatusHttp());
        assertEquals("academic_service_unavailable", ex503.getCodigo());

        ByteArrayOutputStream out503 = new ByteArrayOutputStream();
        loginHandler.handle(reqBloqueada, new RespostaHttp(out503));
        String http503 = new String(out503.toByteArray(), StandardCharsets.UTF_8);
        assertTrue(http503.startsWith("HTTP/1.1 503 Service Unavailable\r\n"));
        MonitorBackendAcademico.desativar();

        // Etapa D: Excecoes tipadas (throws) na camada de seguranca e protocolo
        RequisicaoHttp reqSemAuth = criarRequisicaoHttp("GET", "/api/auth/me", "", "");
        JwtAuthValidator.HttpSecurityException ex401 = assertThrows(
                JwtAuthValidator.HttpSecurityException.class,
                () -> JwtAuthValidator.autenticarObrigatorio(reqSemAuth, repositorio, false)
        );
        assertEquals(401, ex401.getStatusHttp());
        assertEquals("authentication_required", ex401.getCodigo());

        String tokenValido = JwtGerador.gerarAccessToken(repositorio.usuario, 3);
        String tokenAdulterado = tokenValido.substring(0, tokenValido.length() - 4) + "XXXX";
        assertThrows(SecurityException.class,
                () -> JwtAuthValidator.validarToken(tokenAdulterado, JWT_SECRET_TESTE, "access"));

        String refresh = JwtGerador.gerarRefreshToken(repositorio.usuario, 3);
        assertThrows(SecurityException.class,
                () -> JwtAuthValidator.validarToken(refresh, JWT_SECRET_TESTE, "access"));

        RespostaHttp respUnica = new RespostaHttp(new ByteArrayOutputStream());
        respUnica.enviarJson(200, "{\"ok\":true}");
        assertThrows(IOException.class, () -> respUnica.enviarJson(500, "{\"erro\":\"duplo\"}"));
    }

    private static RequisicaoHttp criarRequisicaoHttp(
            String metodo, String caminho, String corpo, String cabecalhosExtras) throws IOException {
        byte[] corpoBytes = corpo.getBytes(StandardCharsets.UTF_8);
        StringBuilder raw = new StringBuilder();
        raw.append(metodo).append(" ").append(caminho).append(" HTTP/1.1\r\n");
        raw.append("Host: 127.0.0.1:8080\r\n");
        raw.append("Content-Type: application/json\r\n");
        raw.append("Content-Length: ").append(corpoBytes.length).append("\r\n");
        if (cabecalhosExtras != null && !cabecalhosExtras.isEmpty()) {
            raw.append(cabecalhosExtras);
        }
        raw.append("\r\n");
        raw.append(corpo);
        return RequisicaoHttp.ler(new ByteArrayInputStream(raw.toString().getBytes(StandardCharsets.UTF_8)));
    }

    private static Map<String, Object> extrairCorpoJson(String respostaHttpCrua) {
        int sep = respostaHttpCrua.indexOf("\r\n\r\n");
        assertTrue(sep > 0, "Resposta HTTP deve conter separador CRLF CRLF");
        String corpo = respostaHttpCrua.substring(sep + 4);
        return Json.analisarObjeto(corpo);
    }

    private static final class RepositorioUsuariosStub extends RepositorioUsuarios {
        final UsuarioAutenticado usuario;
        private final String passwordHash;
        private final Map<String, Long> sessoesAtivas = new HashMap<String, Long>();
        final List<String> eventosAuditoria = new ArrayList<String>();
        String ultimoIpSessao;

        RepositorioUsuariosStub(UsuarioAutenticado usuario, String passwordHash) {
            super(false);
            this.usuario = usuario;
            this.passwordHash = passwordHash;
        }

        @Override
        public UsuarioAutenticado autenticar(String identidade, String senha) {
            boolean bateIdentidade = usuario.getIdentity().equalsIgnoreCase(identidade)
                    || usuario.getEmail().equalsIgnoreCase(identidade);
            if (!bateIdentidade) {
                SenhaHasher.hashDummy();
                return null;
            }
            return SenhaHasher.verificar(senha, passwordHash) ? usuario : null;
        }

        @Override
        public UsuarioAutenticado buscarPorId(String userId) {
            return usuario.getUserId().equals(userId) ? usuario : null;
        }

        @Override
        public UsuarioAutenticado buscarPorIdentidade(String identidade) {
            return usuario.getIdentity().equalsIgnoreCase(identidade) ? usuario : null;
        }

        @Override
        public UsuarioAutenticado buscarPorEmail(String email) {
            return usuario.getEmail().equalsIgnoreCase(email) ? usuario : null;
        }

        @Override
        public void criarSessao(String userId, String sessionId, long expiresAtMillis, String ua, String ip) {
            sessoesAtivas.put(sessionId, Long.valueOf(expiresAtMillis));
            this.ultimoIpSessao = ip;
        }

        @Override
        public boolean sessaoAtiva(String sessionId) {
            Long exp = sessoesAtivas.get(sessionId);
            return exp != null && exp.longValue() > System.currentTimeMillis();
        }

        @Override
        public ResultadoValidacaoSessao validarSessaoCompleta(
                String uid, String sid, int ver, String prof, boolean allowPwd) {
            if (!usuario.getUserId().equals(uid) || !sessaoAtiva(sid)) {
                return ResultadoValidacaoSessao.erro(401, "session_revoked", "Sessao invalida ou revogada.");
            }
            if (ver != usuario.getSessionVersion()) {
                return ResultadoValidacaoSessao.erro(401, "session_version_mismatch", "Sessao obsoleta.");
            }
            return ResultadoValidacaoSessao.ok(usuario);
        }

        @Override
        public void registrarAuditoria(
                String actorId, String action, String target, Map<String, Object> details, String ip) {
            eventosAuditoria.add(action);
        }

        public List<String> getEventosAuditoria() {
            return Collections.unmodifiableList(eventosAuditoria);
        }
    }
}
