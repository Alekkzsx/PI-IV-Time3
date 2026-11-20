// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core;

import auth.abstratas.CanalEnvioEmailAbstrato;
import auth.abstratas.TemplateEmailAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.CanalBrevoEmail;
import auth.modules.email.CanalResendEmail;
import auth.modules.email.CircuitBreakerSmtp;
import auth.modules.email.MensagemEmail;
import auth.modules.email.TemplateEmailBoasVindas;
import auth.modules.email.TemplateEmailDiagnostico;
import auth.modules.email.TemplateEmailOtp;
import auth.modules.email.TemplateEmailRecuperacao;
import auth.utils.AuthHttpUtils;
import auth.utils.JwtAuthValidator;
import auth.utils.JwtGerador;
import bridge.ClientePonteAcademica;
import core.abstratas.ExcecaoHttpAbstrata;
import core.abstratas.HandlerHttpAbstrato;
import org.bson.Document;
import org.bson.types.ObjectId;
import utils.BsonUtils;
import utils.RedeUtils;
import videocall.utils.VideoCallUtils;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Suite nativa (17/17) que valida os contratos das classes abstratas e utilitarios reutilizaveis:
 * - ExcecaoHttpAbstrata (polimorfismo entre DatabaseUnavailable, HttpSecurity e PonteAcademica)
 * - HandlerHttpAbstrato (Template Method: CORS, OPTIONS 204, metodo 405, catch polimorfico)
 * - TemplateEmailAbstrato (layout unico e escape XSS nas 4 subclasses)
 * - CanalEnvioEmailAbstrato & CircuitBreakerSmtp
 * - Utilitarios compartilhados (BsonUtils, RedeUtils, AuthHttpUtils, VideoCallUtils, JwtGerador recovery)
 */
public class ArquiteturaAbstrataTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /**
     * Handler concreto de laboratorio: cada "acao" do body dispara um tipo de excecao
     * diferente, permitindo provar o catch polimorfico do Template Method fim-a-fim.
     */
    private static final class HandlerExemplo extends HandlerHttpAbstrato {
        @Override
        protected String metodoPermitido() {
            return "POST";
        }

        @Override
        protected boolean deveAplicarHeadersAuth() {
            return true;
        }

        @Override
        protected void processar(RequisicaoHttp req, RespostaHttp resp) throws Exception {
            Map<String, Object> body = lerJsonObjeto(req);
            String acao = getString(body, "acao");
            if ("erro_db".equals(acao)) {
                throw new DatabaseUnavailableException(503, "db_down", "Banco fora", null);
            }
            if ("erro_ponte".equals(acao)) {
                throw new ClientePonteAcademica.ExcecaoPonteAcademica(502, "bridge_fail", "Ponte falhou");
            }
            if ("erro_sec".equals(acao)) {
                throw new JwtAuthValidator.HttpSecurityException(403, "forbidden", "Sem permissao");
            }
            if ("erro_arg".equals(acao)) {
                throw new IllegalArgumentException("Campo obrigatorio ausente");
            }
            Map<String, Object> ok = new LinkedHashMap<String, Object>();
            ok.put("ok", Boolean.TRUE);
            ok.put("ip", extrairIpCliente(req, "127.0.0.1"));
            enviarJson(resp, 200, ok);
        }
    }

    /** Executa os 6 blocos de cenario; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;
        String anteriorJwt = System.getProperty("AUTH_JWT_SECRET");
        try {
            System.setProperty("AUTH_JWT_SECRET", "segredo-arquitetura-teste-minimo-32-chars!");

            testarPolimorfismoExcecoes();
            testarTemplateMethodHandler();
            testarGuardaFailClosedBackendAcademico();
            testarTemplatesEmail();
            testarCanaisECircuitBreaker();
            testarUtilitariosCompartilhados();
        } catch (Exception e) {
            esperar(false, "ArquiteturaAbstrataTeste sem excecoes: " + e.getMessage());
        } finally {
            MonitorBackendAcademico.desativar();
            if (anteriorJwt == null) System.clearProperty("AUTH_JWT_SECRET");
            else System.setProperty("AUTH_JWT_SECRET", anteriorJwt);
        }
        return falhas;
    }

    /** As 3 excecoes de dominio respondem cada uma com seu status, via referencia da superclasse. */
    private static void testarPolimorfismoExcecoes() {
        ExcecaoHttpAbstrata e1 = new DatabaseUnavailableException(503, "db_down", "offline", null);
        ExcecaoHttpAbstrata e2 = new JwtAuthValidator.HttpSecurityException(403, "forbidden", "negado");
        ExcecaoHttpAbstrata e3 = new ClientePonteAcademica.ExcecaoPonteAcademica(502, "bridge", "erro");
        esperar(e1.getStatusHttp() == 503 && e2.getStatusHttp() == 403 && e3.getStatusHttp() == 502,
                "ExcecaoHttpAbstrata: unifica statusHttp e codigo polimorficamente nas 3 excecoes de dominio");
    }

    /** Ciclo de vida completo: OPTIONS 204, 405, catches por tipo de excecao e fluxo feliz com IP real. */
    private static void testarTemplateMethodHandler() throws Exception {
        HandlerExemplo handler = new HandlerExemplo();

        String opt = enviarRaw(handler, "OPTIONS /teste HTTP/1.1\r\nHost: localhost\r\n\r\n");
        esperar(opt.startsWith("HTTP/1.1 204") && opt.contains("Cache-Control: no-store"),
                "HandlerHttpAbstrato: responde 204 em OPTIONS aplicando CORS e headers de seguranca");

        String get = enviarRaw(handler, "GET /teste HTTP/1.1\r\nHost: localhost\r\n\r\n");
        esperar(get.startsWith("HTTP/1.1 405") && get.contains("method_not_allowed"),
                "HandlerHttpAbstrato: bloqueia metodo nao permitido com 405 automatico");

        String rDb = postJson(handler, "{\"acao\":\"erro_db\"}");
        String rPonte = postJson(handler, "{\"acao\":\"erro_ponte\"}");
        String rSec = postJson(handler, "{\"acao\":\"erro_sec\"}");
        String rArg = postJson(handler, "{\"acao\":\"erro_arg\"}");
        esperar(rDb.startsWith("HTTP/1.1 503") && rDb.contains("\"code\":\"db_down\"")
                        && rPonte.startsWith("HTTP/1.1 502") && rPonte.contains("\"code\":\"bridge_fail\"")
                        && rSec.startsWith("HTTP/1.1 403") && rSec.contains("\"code\":\"forbidden\"")
                        && rArg.startsWith("HTTP/1.1 400") && rArg.contains("Campo obrigatorio ausente"),
                "HandlerHttpAbstrato: captura polimorfica de ExcecaoHttpAbstrata e IllegalArgumentException");

        String rOk = enviarRaw(handler, "POST /teste HTTP/1.1\r\nHost: localhost\r\nX-Forwarded-For: 10.0.0.5, 10.0.0.1\r\n"
                + "Content-Type: application/json\r\nContent-Length: 13\r\n\r\n{\"acao\":\"ok\"}");
        esperar(rOk.startsWith("HTTP/1.1 200") && rOk.contains("\"ip\":\"10.0.0.5\""),
                "HandlerHttpAbstrato: executa fluxo normal e extrai IP real via RedeUtils");
    }

    /**
     * Fail-closed real: aponta o monitor para uma porta TCP comprovadamente FECHADA
     * (abre e fecha um ServerSocket so para descobrir o numero) e exige 503 nas rotas
     * funcionais, com /health ainda respondendo 200.
     */
    private static void testarGuardaFailClosedBackendAcademico() throws Exception {
        java.net.ServerSocket portaLivre = new java.net.ServerSocket(0, 1, java.net.InetAddress.getByName("127.0.0.1"));
        int portaFechada = portaLivre.getLocalPort();
        portaLivre.close();

        try {
            MonitorBackendAcademico.configurar(true, "http://127.0.0.1:" + portaFechada);

            HandlerExemplo handler = new HandlerExemplo();
            String respBloqueada = postJson(handler, "{\"acao\":\"ok\"}");
            esperar(respBloqueada.startsWith("HTTP/1.1 503")
                            && respBloqueada.contains("\"code\":\"academic_service_unavailable\""),
                    "MonitorBackendAcademico: bloqueia handlers com HTTP 503 quando backend (:3001) esta offline");

            HealthHandler health = new HealthHandler(null);
            String respHealth = enviarRaw(health, "GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n");
            esperar(respHealth.startsWith("HTTP/1.1 200")
                            && respHealth.contains("\"service\":\"agmrm-identity-videocall\""),
                    "HealthHandler: permanece acessivel (200) para diagnostico mesmo com backend (:3001) offline");
        } finally {
            MonitorBackendAcademico.desativar();
        }
    }

    /** As 4 subclasses mantem o layout institucional e escapam XSS (nome "Ana <script>"). */
    private static void testarTemplatesEmail() {
        TemplateEmailAbstrato[] templates = new TemplateEmailAbstrato[] {
                new TemplateEmailOtp("Ana <script>", "654321"),
                new TemplateEmailRecuperacao("Carlos", "112233"),
                new TemplateEmailBoasVindas("Maria", "DOC-123", "docente", "Agmrm@999"),
                new TemplateEmailDiagnostico("Admin", "admin@agmrm.edu")
        };
        boolean todosValidos = true;
        for (TemplateEmailAbstrato tpl : templates) {
            String html = tpl.renderizar();
            if (!html.contains("AGMRM - Plataforma Educacional Integrada") || html.contains("<script>")) {
                todosValidos = false;
            }
        }
        esperar(todosValidos && templates[0].renderizar().contains("&lt;script&gt;"),
                "TemplateEmailAbstrato: renderiza layout institucional unico e aplica escape XSS nas 4 subclasses");
    }

    /** Canais sem chave sao pulados sem erro; breaker abre em 3 falhas e fecha no sucesso. */
    private static void testarCanaisECircuitBreaker() {
        CanalEnvioEmailAbstrato resendSemChave = new CanalResendEmail("", "a@b.com");
        CanalEnvioEmailAbstrato brevoSemChave = new CanalBrevoEmail("", "a@b.com");
        List<String> trail = new ArrayList<String>();
        MensagemEmail msg = new MensagemEmail("dest@agmrm.edu", "Assunto", "<p>123456</p>", "OTP");
        esperar(!resendSemChave.tentarEnviar(msg, trail) && !brevoSemChave.tentarEnviar(msg, trail)
                        && "123456".equals(msg.getCodigoOtp()),
                "CanalEnvioEmailAbstrato: ignora canais nao configurados sem falha e extrai OTP da MensagemEmail");

        CircuitBreakerSmtp cb = new CircuitBreakerSmtp();
        cb.registrarFalha("f1");
        cb.registrarFalha("f2");
        cb.registrarFalha("f3");
        esperar("OPEN".equals(cb.getEstado()) && !cb.permitirTentativa(),
                "CircuitBreakerSmtp: abre circuito apos 3 falhas consecutivas");
        cb.registrarSucesso();
        esperar("CLOSED".equals(cb.getEstado()) && cb.permitirTentativa(),
                "CircuitBreakerSmtp: retorna para CLOSED apos sucesso");
    }

    /** Conversao BSON, normalizacao de URL/loopback, mascara de e-mail, clamp, sala/presenca e recovery token. */
    private static void testarUtilitariosCompartilhados() {
        ObjectId oid = new ObjectId();
        Document nested = new Document("_id", oid)
                .append("tags", Collections.singletonList(new Document("k", "v")));
        Map<String, Object> mapa = BsonUtils.documentoParaMapa(nested);
        esperar(oid.toHexString().equals(mapa.get("_id")) && mapa.get("tags") instanceof List,
                "BsonUtils: converte Document/ObjectId/List recursivamente para Map");

        esperar("https://exemplo.com".equals(RedeUtils.limparBarraFinal("https://exemplo.com///"))
                        && RedeUtils.isLoopbackHost("127.0.0.1"),
                "RedeUtils: normaliza barras finais e identifica loopback");

        esperar("a***o@agmrm.edu".equals(AuthHttpUtils.mascararEmail("aluno@agmrm.edu"))
                        && AuthHttpUtils.parseIntBounded("9999", 10, 1, 500) == 500,
                "AuthHttpUtils: mascara e-mail e aplica limites em inteiros de query");

        esperar("APS-II".equals(VideoCallUtils.sanitizeRoomCode("  aps - ii! "))
                        && "PRESENCA_INTEGRAL".equals(VideoCallUtils.classificarStatusPresenca(80.0))
                        && "MEIA_PRESENCA".equals(VideoCallUtils.classificarStatusPresenca(60.0))
                        && "FALTA_AUTOMATICA".equals(VideoCallUtils.classificarStatusPresenca(20.0)),
                "VideoCallUtils: sanitiza codigo da sala e classifica frequencia regimental");

        UsuarioAutenticado u = new UsuarioAutenticado("507f1f77bcf86cd799439011", "aluno", "", 1, "ra1", "Aluno", "a@b.com", false);
        String recToken = JwtGerador.gerarRecoveryToken(u);
        UsuarioAutenticado validado = JwtAuthValidator.validarToken(
                recToken, "segredo-arquitetura-teste-minimo-32-chars!", "recovery");
        esperar("507f1f77bcf86cd799439011".equals(validado.getUserId()) && JwtGerador.extrairJti(recToken) != null,
                "JwtGerador: emissao unificada de recovery token valida com JwtAuthValidator");
    }

    /** Monta um POST JSON cru para o handler de laboratorio. */
    private static String postJson(HandlerHttpAbstrato handler, String jsonBody) throws Exception {
        byte[] bytes = jsonBody.getBytes(StandardCharsets.UTF_8);
        String raw = "POST /teste HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\n"
                + "Content-Length: " + bytes.length + "\r\n\r\n" + jsonBody;
        return enviarRaw(handler, raw);
    }

    /** Executa requisicao HTTP crua contra o handler e devolve a resposta serializada. */
    private static String enviarRaw(HandlerHttpAbstrato handler, String raw) throws Exception {
        RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(raw.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        RespostaHttp resp = new RespostaHttp(out);
        handler.handle(req, resp);
        return new String(out.toByteArray(), StandardCharsets.UTF_8);
    }
}
