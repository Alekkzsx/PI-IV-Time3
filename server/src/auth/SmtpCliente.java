// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import utils.ConfigEnv;
import utils.Json;

import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Cliente SMTP implementado 100% na unha usando java.net.Socket, sem nenhuma biblioteca externa.
 * Envia emails transacionais (OTP, recuperacao de senha) diretamente via protocolo SMTP (RFC 5321).
 *
 * Caracteristicas:
 * - Envio assincrono via ExecutorService (nao bloqueia a resposta HTTP)
 * - Retry com backoff exponencial (1s, 2s, 4s)
 * - Subject com encoding RFC 2047 (suporte a acentos UTF-8)
 * - Timeout configuravel via .env (SMTP_TIMEOUT_MS)
 * - Logs estruturados com niveis (INFO, WARN, ERROR)
 * - Fallback para webhook HTTP (GMAIL_WEBHOOK_URL) quando SMTP falha
 * - Suporte a SMTPS (porta 465 SSL) e STARTTLS (porta 587)
 * - Autenticacao LOGIN (AUTH LOGIN)
 * - Modo sandbox (SMTP_SANDBOX_MODE=true) para desenvolvimento
 *
 * Variaveis de ambiente (.env):
 * - SMTP_HOST: host do servidor SMTP (ex: smtp.gmail.com)
 * - SMTP_PORT: porta do servidor (465, 587 ou 25)
 * - SMTP_SECURE / SMTP_SSL: usar SSL/TLS
 * - SMTP_USER: usuario para autenticacao
 * - SMTP_PASSWORD: senha para autenticacao
 * - SMTP_FROM: endereco do remetente
 * - SMTP_TIMEOUT_MS: timeout de conexao/leitura em ms (padrao: 15000)
 * - SMTP_MAX_RETRIES: numero maximo de tentativas (padrao: 3)
 * - SMTP_POOL_SIZE: tamanho do pool de threads (padrao: 3)
 * - SMTP_SANDBOX_MODE: se true, nao dispara email real (padrao: false)
 * - SMTP_LOG_HTML: se true, imprime HTML no console (padrao: false)
 * - GMAIL_WEBHOOK_URL: URL de fallback quando SMTP falha
 */
public final class SmtpCliente {

    private static final DateTimeFormatter LOG_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private static final ThreadFactory THREAD_FACTORY = new ThreadFactory() {
        private final AtomicInteger counter = new AtomicInteger(1);
        @Override
        public Thread newThread(Runnable r) {
            Thread t = new Thread(r, "smtp-worker-" + counter.getAndIncrement());
            t.setDaemon(true);
            return t;
        }
    };

    private static final ExecutorService FILA_EMAILS = Executors.newFixedThreadPool(
            ConfigEnv.obterInteiro("SMTP_POOL_SIZE", 3),
            THREAD_FACTORY
    );

    // Buffer circular em memoria dos ultimos 50 emails despachados (Tier 3 Outbox)
    private static final Queue<EmailOutboxItem> OUTBOX_HISTORICO = new ConcurrentLinkedQueue<EmailOutboxItem>();
    private static final Pattern OTP_PATTERN = Pattern.compile("(?<!\\d)(\\d{6})(?!\\d)");
    private static final Pattern EMAIL_ANGULO_PATTERN = Pattern.compile("<([^>]+)>");
    private static final int MAX_FALHAS_CIRCUITO = 3;
    private static final long COOLDOWN_CIRCUITO_MS = 60_000L;
    private static final int WEBHOOK_TIMEOUT_MS = 12_000;
    private static final Object CIRCUITO_LOCK = new Object();
    private static String estadoCircuito = "CLOSED";
    private static int falhasConsecutivasSmtp = 0;
    private static long proximaTentativaSmtpMs = 0L;

    /**
     * Resultado detalhado de um disparo resiliente de e-mail para diagnostico e auditoria.
     */
    public static final class ResultadoEnvioEmail {
        private final String canal;
        private final boolean deliveredExternally;
        private final List<String> errorTrail;
        private final long latenciaMs;

        public ResultadoEnvioEmail(String canal, boolean deliveredExternally, List<String> errorTrail, long latenciaMs) {
            this.canal = canal;
            this.deliveredExternally = deliveredExternally;
            this.errorTrail = errorTrail == null
                    ? Collections.<String>emptyList()
                    : Collections.unmodifiableList(new ArrayList<String>(errorTrail));
            this.latenciaMs = latenciaMs;
        }

        public String getCanal() { return canal; }
        public boolean isDeliveredExternally() { return deliveredExternally; }
        public List<String> getErrorTrail() { return errorTrail; }
        public long getLatenciaMs() { return latenciaMs; }
    }

    static final class SmtpConfig {
        final String host;
        final int porta;
        final boolean usarSsl;
        final String usuario;
        final String senha;
        final String remetente;
        final int timeoutMs;

        SmtpConfig(String host, int porta, boolean usarSsl, String usuario, String senha, String remetente, int timeoutMs) {
            this.host = host != null ? host.trim() : "";
            this.porta = porta;
            this.usarSsl = usarSsl;
            this.usuario = usuario != null ? usuario.trim() : "";
            this.senha = senha != null ? senha : "";
            String bruto = (remetente != null && !remetente.trim().isEmpty()) ? remetente : this.usuario;
            this.remetente = extrairEmailPuro(bruto);
            this.timeoutMs = timeoutMs > 0 ? timeoutMs : 10_000;
        }

        static SmtpConfig fromEnv() {
            String usuario = ConfigEnv.obter("SMTP_USER", "");
            return new SmtpConfig(
                    ConfigEnv.obter("SMTP_HOST", ""),
                    ConfigEnv.obterInteiro("SMTP_PORT", 587),
                    "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SECURE", "false"))
                            || "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SSL", "false")),
                    usuario,
                    ConfigEnv.obter("SMTP_PASSWORD", ""),
                    ConfigEnv.obter("SMTP_FROM", usuario),
                    ConfigEnv.obterInteiro("SMTP_TIMEOUT_MS", 10_000)
            );
        }
    }

    static final class HttpsRelayConfig {
        final String resendApiKey;
        final String brevoApiKey;
        final String webhookUrl;
        final String remetente;

        HttpsRelayConfig(String resendApiKey, String brevoApiKey, String webhookUrl, String remetente) {
            this.resendApiKey = resendApiKey != null ? resendApiKey.trim() : "";
            this.brevoApiKey = brevoApiKey != null ? brevoApiKey.trim() : "";
            this.webhookUrl = webhookUrl != null ? webhookUrl.trim() : "";
            String limpo = extrairEmailPuro(remetente);
            this.remetente = limpo.isEmpty() ? "portal.academico@agmrm.edu.br" : limpo;
        }

        static HttpsRelayConfig fromEnv() {
            String usuario = ConfigEnv.obter("SMTP_USER", "");
            return new HttpsRelayConfig(
                    ConfigEnv.obter("RESEND_API_KEY", ""),
                    ConfigEnv.obter("BREVO_API_KEY", ""),
                    ConfigEnv.obter("GMAIL_WEBHOOK_URL", ""),
                    ConfigEnv.obter("SMTP_FROM", usuario)
            );
        }
    }

    /**
     * Registro de um e-mail retido no Outbox em memoria para auditoria e resiliencia.
     */
    public static final class EmailOutboxItem {
        private final String destinatario;
        private final String assunto;
        private final String codigoOtp;
        private final String tipo;
        private final String canal;
        private final long timestamp;

        public EmailOutboxItem(String destinatario, String assunto, String codigoOtp, String tipo, String canal) {
            this.destinatario = destinatario;
            this.assunto = assunto;
            this.codigoOtp = codigoOtp;
            this.tipo = tipo;
            this.canal = canal;
            this.timestamp = System.currentTimeMillis();
        }

        public String getDestinatario() { return destinatario; }
        public String getAssunto() { return assunto; }
        public String getCodigoOtp() { return codigoOtp; }
        public String getTipo() { return tipo; }
        public String getCanal() { return canal; }
        public long getTimestamp() { return timestamp; }
    }

    public static List<EmailOutboxItem> getHistoricoOutbox() {
        return new ArrayList<EmailOutboxItem>(OUTBOX_HISTORICO);
    }

    public static String getEstadoCircuito() {
        synchronized (CIRCUITO_LOCK) {
            return estadoCircuito;
        }
    }

    static void resetarCircuitoParaTeste() {
        synchronized (CIRCUITO_LOCK) {
            estadoCircuito = "CLOSED";
            falhasConsecutivasSmtp = 0;
            proximaTentativaSmtpMs = 0L;
        }
    }

    private SmtpCliente() {}

    // =========================================================================
    // API PUBLICA - ENVIO ASSINCRONO
    // =========================================================================

    /**
     * Valida sintaticamente um endereco de e-mail institucional ou pessoal.
     */
    public static boolean isEmailValido(String email) {
        if (email == null) return false;
        String limpo = email.trim();
        if (limpo.isEmpty() || limpo.length() > 254 || limpo.contains(" ")) return false;
        int arroba = limpo.indexOf('@');
        if (arroba <= 0 || arroba != limpo.lastIndexOf('@')) return false;
        String dominio = limpo.substring(arroba + 1);
        int ponto = dominio.indexOf('.');
        return ponto > 0 && ponto < dominio.length() - 1;
    }

    /**
     * Envia um email com codigo OTP para o usuario (assincrono, nao bloqueia).
     *
     * @param destinatarioEmail Email do destinatario.
     * @param codigoOTP         Codigo OTP de 6 digitos.
     * @param nomeUsuario       Nome de exibicao do usuario.
     */
    public static void enviarOtp(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        enviarOtpComResultado(destinatarioEmail, codigoOTP, nomeUsuario);
    }

    /**
     * Envia OTP de autenticacao assincronamente retornando o resultado detalhado da entrega.
     */
    public static CompletableFuture<ResultadoEnvioEmail> enviarOtpComResultado(
            String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String assunto = "Seu código de verificação - AGMRM";
        String corpoHtml = construirHtmlOtp(codigoOTP, nomeUsuario);
        return enviarAsyncDetalhado(destinatarioEmail, assunto, corpoHtml, "OTP");
    }

    /**
     * Envia um email de boas-vindas ao usuario recem-cadastrado pelo Admin (assincrono).
     */
    public static void enviarBoasVindas(
            String destinatarioEmail,
            String nomeUsuario,
            String identidade,
            String perfil,
            String senhaTemporaria) {
        enviarBoasVindasComResultado(destinatarioEmail, nomeUsuario, identidade, perfil, senhaTemporaria);
    }

    /**
     * Envia um email de boas-vindas assincrono retornando telemetria de entrega.
     */
    public static CompletableFuture<ResultadoEnvioEmail> enviarBoasVindasComResultado(
            String destinatarioEmail,
            String nomeUsuario,
            String identidade,
            String perfil,
            String senhaTemporaria) {
        if (destinatarioEmail == null || destinatarioEmail.trim().isEmpty()) {
            return CompletableFuture.completedFuture(
                    new ResultadoEnvioEmail("OUTBOX", false, Collections.singletonList("Destinatario vazio"), 0L));
        }
        String assunto = "Bem-vindo ao Portal AGMRM — Credenciais de Acesso";
        String corpoHtml = construirHtmlBoasVindas(nomeUsuario, identidade, perfil, senhaTemporaria);
        return enviarAsyncDetalhado(destinatarioEmail.trim(), assunto, corpoHtml, "WELCOME");
    }

    /**
     * Envia um email de recuperacao de senha (assincrono, nao bloqueia).
     *
     * @param destinatarioEmail Email do destinatario.
     * @param codigoOTP         Codigo OTP de recuperacao.
     * @param nomeUsuario       Nome de exibicao do usuario.
     */
    public static void enviarRecuperacao(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        enviarRecuperacaoComResultado(destinatarioEmail, codigoOTP, nomeUsuario);
    }

    /**
     * Envia email de recuperacao assincronamente retornando telemetria detalhada da entrega.
     */
    public static CompletableFuture<ResultadoEnvioEmail> enviarRecuperacaoComResultado(
            String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String assunto = "Recuperação de senha - AGMRM";
        String corpoHtml = construirHtmlRecuperacao(codigoOTP, nomeUsuario);
        return enviarAsyncDetalhado(destinatarioEmail, assunto, corpoHtml, "RECOVERY");
    }

    /**
     * Envia um email generico de forma assincrona (nao bloqueia o handler HTTP).
     *
     * @param destinatarioEmail Email do destinatario.
     * @param assunto           Assunto do email.
     * @param corpoHtml         Corpo do email em HTML.
     * @param tipo              Tipo do email para logging (ex: "OTP", "RECOVERY").
     * @return CompletableFuture para aguardar o envio (opcional).
     */
    public static CompletableFuture<Void> enviarAsync(
            String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return enviarAsyncDetalhado(destinatarioEmail, assunto, corpoHtml, tipo)
                .thenApply(resultado -> null);
    }

    /**
     * Envia um email de forma assincrona retornando telemetria completa do canal usado.
     */
    public static CompletableFuture<ResultadoEnvioEmail> enviarAsyncDetalhado(
            String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return CompletableFuture.supplyAsync(() -> enviarComRetry(destinatarioEmail, assunto, corpoHtml, tipo), FILA_EMAILS);
    }

    /**
     * Envia um email de forma sincrona (bloqueia ate concluir ou falhar).
     * Usado principalmente em testes.
     */
    public static void enviarSincrono(String destinatarioEmail, String assunto, String corpoHtml) throws Exception {
        enviarSmtp(destinatarioEmail, assunto, corpoHtml);
    }

    /**
     * Envia um email de forma sincrona percorrendo todos os 3 tiers de resiliencia (SMTP -> HTTPS -> Outbox).
     * Retorna o canal efetivo utilizado ("SMTP", "RESEND", "BREVO", "WEBHOOK" ou "OUTBOX").
     */
    public static String enviarSincronoResiliente(String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return enviarSincronoDetalhado(destinatarioEmail, assunto, corpoHtml, tipo).getCanal();
    }

    /**
     * Envia um email de forma sincrona percorrendo os 3 tiers de resiliencia e retornando telemetria completa.
     */
    public static ResultadoEnvioEmail enviarSincronoDetalhado(
            String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return despacharResiliente(
                SmtpConfig.fromEnv(),
                HttpsRelayConfig.fromEnv(),
                destinatarioEmail,
                assunto,
                corpoHtml,
                tipo,
                1,
                "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"))
        );
    }

    // =========================================================================
    // LOGICA DE RESILIENCIA, CIRCUIT BREAKER E RETRY COM BACKOFF EXPONENCIAL
    // =========================================================================

    private static ResultadoEnvioEmail enviarComRetry(String destinatario, String assunto, String html, String tipo) {
        int maxTentativas = ConfigEnv.obterInteiro("SMTP_MAX_RETRIES", 1);
        if (maxTentativas < 1) maxTentativas = 1;
        return despacharResiliente(
                SmtpConfig.fromEnv(),
                HttpsRelayConfig.fromEnv(),
                destinatario,
                assunto,
                html,
                tipo,
                maxTentativas,
                "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"))
        );
    }

    static ResultadoEnvioEmail despacharResiliente(
            SmtpConfig smtpConfig,
            HttpsRelayConfig httpsConfig,
            String destinatario,
            String assunto,
            String html,
            String tipo,
            int maxTentativasSmtp,
            boolean sandboxMode) {
        long inicioTotal = System.currentTimeMillis();
        List<String> errorTrail = new ArrayList<String>();

        if (sandboxMode) {
            log("INFO", "[SANDBOX] Email simulado para: " + destinatario + " | Tipo: " + tipo);
            errorTrail.add("Modo sandbox ativo (SMTP_SANDBOX_MODE=true)");
            acionarLocalOutbox(destinatario, assunto, html, tipo, errorTrail);
            if ("true".equalsIgnoreCase(ConfigEnv.obter("SMTP_LOG_HTML", "false"))) {
                log("DEBUG", "[SANDBOX] Assunto: " + assunto + "\n" + html);
            }
            return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
        }

        // Tier 1: SMTP com retry exponencial e Circuit Breaker
        if (podeTentarSmtp(smtpConfig)) {
            long delayMs = 1000L;
            int tentativas = Math.max(1, maxTentativasSmtp);
            for (int tentativa = 1; tentativa <= tentativas; tentativa++) {
                try {
                    long inicio = System.currentTimeMillis();
                    enviarSmtpComConfig(smtpConfig, destinatario, assunto, html);
                    long latencia = System.currentTimeMillis() - inicio;
                    registrarSucessoSmtp();
                    log("INFO", "[ENVIO OK] Tipo=" + tipo + " | Para=" + destinatario
                            + " | Tentativa=" + tentativa + "/" + tentativas
                            + " | Latencia=" + latencia + "ms");
                    OUTBOX_HISTORICO.offer(new EmailOutboxItem(destinatario, assunto, extrairCodigoOtp(html), tipo, "SMTP"));
                    return new ResultadoEnvioEmail("SMTP", true, errorTrail, System.currentTimeMillis() - inicioTotal);
                } catch (Exception e) {
                    String msgErro = "SMTP tentativa " + tentativa + "/" + tentativas + ": "
                            + (e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
                    errorTrail.add(msgErro);
                    registrarFalhaSmtp(msgErro);
                    log("WARN", "[FALHA SMTP] Tipo=" + tipo + " | Para=" + destinatario
                            + " | Tentativa=" + tentativa + "/" + tentativas
                            + " | Erro: " + e.getMessage());

                    if ("OPEN".equals(getEstadoCircuito())) {
                        break;
                    }
                    if (tentativa < tentativas) {
                        try {
                            Thread.sleep(delayMs);
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            errorTrail.add("Retry SMTP interrompido");
                            log("ERROR", "[INTERRUPCAO] Retry interrompido para " + destinatario);
                            acionarLocalOutbox(destinatario, assunto, html, tipo, errorTrail);
                            return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
                        }
                        delayMs *= 2L;
                    }
                }
            }
        } else if (smtpConfig.host.isEmpty()) {
            errorTrail.add("SMTP nao configurado (SMTP_HOST vazio)");
        } else {
            errorTrail.add("Circuit Breaker OPEN: SMTP ignorado temporariamente");
        }

        // Tier 2: Provedores HTTPS REST na porta 443 (Resend -> Brevo -> Webhook)
        log("WARN", "[SMTP INDISPONIVEL] Acionando Tier 2 (HTTPS REST) para " + destinatario + "...");
        String canalHttps = acionarFallbackHttps(httpsConfig, destinatario, assunto, html, tipo, errorTrail);
        if (canalHttps != null) {
            OUTBOX_HISTORICO.offer(new EmailOutboxItem(destinatario, assunto, extrairCodigoOtp(html), tipo, canalHttps));
            return new ResultadoEnvioEmail(canalHttps, true, errorTrail, System.currentTimeMillis() - inicioTotal);
        }

        // Tier 3: Outbox Local (Zero Crash)
        log("INFO", "[RESILIENCIA ATIVA] Acionando Tier 3 (Outbox Local de Seguranca)...");
        acionarLocalOutbox(destinatario, assunto, html, tipo, errorTrail);
        return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
    }

    private static boolean podeTentarSmtp(SmtpConfig config) {
        if (config == null || config.host.isEmpty()) return false;
        long agora = System.currentTimeMillis();
        synchronized (CIRCUITO_LOCK) {
            if ("CLOSED".equals(estadoCircuito)) return true;
            if ("OPEN".equals(estadoCircuito)) {
                if (agora >= proximaTentativaSmtpMs) {
                    estadoCircuito = "HALF_OPEN";
                    return true;
                }
                return false;
            }
            return true;
        }
    }

    private static void registrarSucessoSmtp() {
        synchronized (CIRCUITO_LOCK) {
            falhasConsecutivasSmtp = 0;
            estadoCircuito = "CLOSED";
            proximaTentativaSmtpMs = 0L;
        }
    }

    private static void registrarFalhaSmtp(String motivo) {
        synchronized (CIRCUITO_LOCK) {
            falhasConsecutivasSmtp++;
            if (falhasConsecutivasSmtp >= MAX_FALHAS_CIRCUITO) {
                estadoCircuito = "OPEN";
                proximaTentativaSmtpMs = System.currentTimeMillis() + COOLDOWN_CIRCUITO_MS;
                log("WARN", "[CIRCUITO SMTP ABERTO] Apos " + falhasConsecutivasSmtp
                        + " falhas consecutivas (" + motivo + "). Cooldown de 60s.");
            }
        }
    }

    // =========================================================================
    // TIER 2: PROVEDORES HTTPS REST (Resend / Brevo / Google Apps Script Webhook)
    // =========================================================================

    static final class HttpResposta {
        final int status;
        final String body;

        HttpResposta(int status, String body) {
            this.status = status;
            this.body = body != null ? body : "";
        }
    }

    static String acionarFallbackHttps(
            HttpsRelayConfig config,
            String destinatario,
            String assunto,
            String html,
            String tipo,
            List<String> errorTrail) {
        if (config == null) {
            errorTrail.add("Nenhum provedor HTTPS configurado");
            return null;
        }

        String textoPlano = extrairTextoPlano(html, assunto);

        if (!config.resendApiKey.isEmpty()) {
            try {
                Map<String, String> headers = new LinkedHashMap<String, String>();
                headers.put("Authorization", "Bearer " + config.resendApiKey);
                Map<String, Object> bodyMap = new LinkedHashMap<String, Object>();
                bodyMap.put("from", config.remetente);
                bodyMap.put("to", Collections.singletonList(destinatario));
                bodyMap.put("subject", assunto);
                bodyMap.put("html", html);
                bodyMap.put("text", textoPlano);

                HttpResposta res = executarPostJsonHttp(
                        "https://api.resend.com/emails", headers, Json.escrever(bodyMap), 5000, 8000, false);
                if (res.status >= 200 && res.status < 300) {
                    log("INFO", "[FALLBACK OK] Resend enviou com sucesso para " + destinatario);
                    return "RESEND";
                }
                errorTrail.add("Resend HTTP " + res.status + ": " + truncar(res.body, 160));
            } catch (Exception e) {
                errorTrail.add("Resend falhou: " + e.getMessage());
            }
        }

        if (!config.brevoApiKey.isEmpty()) {
            try {
                Map<String, String> headers = new LinkedHashMap<String, String>();
                headers.put("api-key", config.brevoApiKey);
                Map<String, Object> sender = new LinkedHashMap<String, Object>();
                sender.put("email", config.remetente);
                sender.put("name", "Portal Acadêmico AGM-RM");
                Map<String, Object> recipient = new LinkedHashMap<String, Object>();
                recipient.put("email", destinatario);
                Map<String, Object> bodyMap = new LinkedHashMap<String, Object>();
                bodyMap.put("sender", sender);
                bodyMap.put("to", Collections.singletonList(recipient));
                bodyMap.put("subject", assunto);
                bodyMap.put("htmlContent", html);
                bodyMap.put("textContent", textoPlano);

                HttpResposta res = executarPostJsonHttp(
                        "https://api.brevo.com/v3/smtp/email", headers, Json.escrever(bodyMap), 5000, 8000, false);
                if (res.status >= 200 && res.status < 300) {
                    log("INFO", "[FALLBACK OK] Brevo enviou com sucesso para " + destinatario);
                    return "BREVO";
                }
                errorTrail.add("Brevo HTTP " + res.status + ": " + truncar(res.body, 160));
            } catch (Exception e) {
                errorTrail.add("Brevo falhou: " + e.getMessage());
            }
        }

        if (!config.webhookUrl.isEmpty()) {
            try {
                Map<String, Object> bodyMap = new LinkedHashMap<String, Object>();
                bodyMap.put("to", destinatario);
                bodyMap.put("from", config.remetente);
                bodyMap.put("subject", assunto);
                bodyMap.put("html", html);
                bodyMap.put("text", textoPlano);
                bodyMap.put("type", tipo);

                HttpResposta res = executarPostJsonHttp(
                        config.webhookUrl,
                        Collections.<String, String>emptyMap(),
                        Json.escrever(bodyMap),
                        6000,
                        WEBHOOK_TIMEOUT_MS,
                        true
                );

                String erroWebhook = validarRespostaWebhook(res.status, res.body);
                if (erroWebhook == null) {
                    log("INFO", "[FALLBACK OK] Webhook enviado com sucesso para " + destinatario + " | HTTP " + res.status);
                    return "WEBHOOK";
                }
                errorTrail.add(erroWebhook);
                log("WARN", "[FALLBACK REJEITADO] " + erroWebhook);
            } catch (Exception e) {
                String msg = "Webhook falhou: " + e.getMessage();
                errorTrail.add(msg);
                log("WARN", "[FALLBACK FALHOU] " + msg);
            }
        } else if (config.resendApiKey.isEmpty() && config.brevoApiKey.isEmpty()) {
            errorTrail.add("Nenhum provedor HTTPS configurado (RESEND_API_KEY, BREVO_API_KEY, GMAIL_WEBHOOK_URL ausentes)");
        }

        return null;
    }

    static String validarRespostaWebhook(int status, String body) {
        if (status < 200 || status >= 300) {
            return "Webhook retornou HTTP " + status + (body != null && !body.trim().isEmpty()
                    ? ": " + truncar(body.trim(), 160) : "");
        }
        String limpo = body != null ? body.trim() : "";
        String lower = limpo.toLowerCase(Locale.ROOT);
        if (lower.contains("<!doctype")
                || lower.contains("<html")
                || lower.contains("accounts.google.com")
                || lower.contains("não foi possível abrir o arquivo")
                || lower.contains("função de script não encontrada")
                || lower.contains("script function not found")
                || lower.contains("errormessage")) {
            return "Webhook retornou pagina/erro invalido em HTTP " + status + ": " + truncar(limpo, 160);
        }
        if (limpo.startsWith("{")) {
            try {
                Map<String, Object> json = Json.analisarObjeto(limpo);
                Object erro = json.get("error");
                if (erro == null) erro = json.get("errorMessage");
                if (erro != null && !String.valueOf(erro).trim().isEmpty()) {
                    return "Webhook reportou erro no corpo: " + erro;
                }
                Object ok = json.get("ok");
                Object success = json.get("success");
                if (Boolean.FALSE.equals(ok) || Boolean.FALSE.equals(success)) {
                    return "Webhook retornou success=false: " + truncar(limpo, 160);
                }
                Object statusJson = json.get("status");
                if (statusJson instanceof Number && ((Number) statusJson).intValue() >= 400) {
                    return "Webhook retornou status interno " + statusJson + ": " + truncar(limpo, 160);
                }
            } catch (IllegalArgumentException ignored) {
                // Resposta textual não-JSON aceita caso não contenha marcadores de erro HTML
            }
        }
        return null;
    }

    private static HttpResposta executarPostJsonHttp(
            String urlDestino,
            Map<String, String> headersExtras,
            String payloadJson,
            int connectTimeoutMs,
            int readTimeoutMs,
            boolean seguirRedirectPost302) throws IOException {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(urlDestino);
            conn = (HttpURLConnection) url.openConnection();
            conn.setInstanceFollowRedirects(false);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Accept", "application/json, text/plain, */*");
            conn.setRequestProperty("User-Agent", "AGMRM-Native-Server/1.0");
            if (headersExtras != null) {
                for (Map.Entry<String, String> entry : headersExtras.entrySet()) {
                    conn.setRequestProperty(entry.getKey(), entry.getValue());
                }
            }
            conn.setDoOutput(true);
            conn.setConnectTimeout(connectTimeoutMs);
            conn.setReadTimeout(readTimeoutMs);

            OutputStream os = conn.getOutputStream();
            os.write(payloadJson.getBytes(StandardCharsets.UTF_8));
            os.flush();
            os.close();

            int status = conn.getResponseCode();
            if (seguirRedirectPost302
                    && (status == HttpURLConnection.HTTP_MOVED_TEMP
                    || status == HttpURLConnection.HTTP_SEE_OTHER
                    || status == 307
                    || status == 308)) {
                String redirectUrl = conn.getHeaderField("Location");
                if (redirectUrl != null && !redirectUrl.trim().isEmpty()) {
                    conn.disconnect();
                    conn = (HttpURLConnection) new URL(redirectUrl.trim()).openConnection();
                    conn.setInstanceFollowRedirects(true);
                    conn.setRequestMethod("GET");
                    conn.setRequestProperty("User-Agent", "AGMRM-Native-Server/1.0");
                    conn.setConnectTimeout(connectTimeoutMs);
                    conn.setReadTimeout(readTimeoutMs);
                    status = conn.getResponseCode();
                }
            }

            InputStream stream = status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream();
            String body = lerStreamSeguro(stream);
            return new HttpResposta(status, body);
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }

    private static String lerStreamSeguro(InputStream stream) throws IOException {
        if (stream == null) return "";
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        byte[] chunk = new byte[4096];
        int lidos;
        try {
            while ((lidos = stream.read(chunk)) != -1) {
                buffer.write(chunk, 0, lidos);
            }
        } finally {
            try { stream.close(); } catch (IOException ignored) { }
        }
        return new String(buffer.toByteArray(), StandardCharsets.UTF_8);
    }

    // =========================================================================
    // TIER 3: LOCAL OUTBOX (RESILIENCIA TOTAL EM CONSOLE E MEMORIA)
    // =========================================================================

    private static void acionarLocalOutbox(
            String destinatario, String assunto, String html, String tipo, List<String> errorTrail) {
        String codigoOtp = extrairCodigoOtp(html);
        EmailOutboxItem item = new EmailOutboxItem(destinatario, assunto, codigoOtp, tipo, "OUTBOX");
        OUTBOX_HISTORICO.offer(item);
        while (OUTBOX_HISTORICO.size() > 50) {
            OUTBOX_HISTORICO.poll();
        }

        String destinatarioFormatado = truncar(destinatario, 56);
        String assuntoFormatado = truncar(assunto, 56);
        String otpFormatado = codigoOtp != null ? codigoOtp : "------";

        StringBuilder moldura = new StringBuilder();
        moldura.append("\n")
                .append("┌════════════════════════════════════════════════════════════════════┐\n")
                .append("│ 📬 [OUTBOX LOCAL / RESILIÊNCIA ATIVA]                               │\n")
                .append(String.format("│ Para:    %-58s │\n", destinatarioFormatado))
                .append(String.format("│ Assunto: %-58s │\n", assuntoFormatado))
                .append("│                                                                    │\n")
                .append(String.format("│   CÓDIGO DE VERIFICAÇÃO OTP:  [ %-6s ]                           │\n", otpFormatado))
                .append("│                                                                    │\n");
        if (errorTrail != null && !errorTrail.isEmpty()) {
            moldura.append("│ Motivos do failover:                                               │\n");
            for (String err : errorTrail) {
                moldura.append(String.format("│ • %-64s │\n", truncar(err, 64)));
            }
        }
        moldura.append("└════════════════════════════════════════════════════════════════════┘\n");

        System.out.println(moldura.toString());
        persistirOutboxMongo(destinatario, assunto, html, codigoOtp, tipo, errorTrail);
        log("INFO", "[OUTBOX REGISTRADO] Email retido em outbox local para " + destinatario + " | OTP=" + otpFormatado);
    }

    private static void persistirOutboxMongo(
            String destinatario, String assunto, String html, String codigoOtp, String tipo, List<String> errorTrail) {
        try {
            RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
            if (repo == null || repo.getEmailOutboxCollection() == null) return;
            java.util.Date agora = new java.util.Date();
            java.util.Date expira = new java.util.Date(System.currentTimeMillis() + 86_400_000L);
            org.bson.Document doc = new org.bson.Document()
                    .append("id", "java_outbox_" + System.currentTimeMillis())
                    .append("to", destinatario)
                    .append("subject", assunto)
                    .append("html", html)
                    .append("text", assunto + (codigoOtp != null ? " | Codigo: " + codigoOtp : ""))
                    .append("provider", "outbox")
                    .append("purpose", tipo)
                    .append("createdAt", agora)
                    .append("expiresAt", expira);
            if (codigoOtp != null) doc.append("code", codigoOtp);
            if (errorTrail != null && !errorTrail.isEmpty()) doc.append("errorTrail", errorTrail);
            repo.getEmailOutboxCollection().insertOne(doc);
        } catch (Exception ignored) { }
    }

    private static String extrairCodigoOtp(String html) {
        if (html == null) return null;
        Matcher m = OTP_PATTERN.matcher(html);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }

    static String extrairEmailPuro(String valor) {
        if (valor == null) return "";
        String limpo = valor.trim();
        Matcher m = EMAIL_ANGULO_PATTERN.matcher(limpo);
        if (m.find()) {
            return m.group(1).trim();
        }
        return limpo;
    }

    static String extrairTextoPlano(String html, String fallbackAssunto) {
        if (html == null || html.trim().isEmpty()) {
            return fallbackAssunto != null ? fallbackAssunto : "";
        }
        String semBlocos = html
                .replaceAll("(?is)<style[^>]*>.*?</style>", " ")
                .replaceAll("(?is)<script[^>]*>.*?</script>", " ")
                .replaceAll("(?i)<br\\s*/?>", "\n")
                .replaceAll("(?i)</p>|</div>|</tr>|</h[1-6]>", "\n")
                .replaceAll("<[^>]+>", " ")
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replaceAll("[ \\t\\x0B\\f\\r]+", " ")
                .replaceAll("\\n\\s+", "\n")
                .trim();
        return semBlocos.isEmpty() ? (fallbackAssunto != null ? fallbackAssunto : "") : semBlocos;
    }

    private static String truncar(String texto, int max) {
        if (texto == null) return "";
        if (texto.length() <= max) return texto;
        return texto.substring(0, max - 3) + "...";
    }

    // =========================================================================
    // PROTOCOLO SMTP (RFC 5321) - IMPLEMENTACAO NATIVA COM CRLF ESTRITO
    // =========================================================================

    private static void enviarSmtp(String destinatarioEmail, String assunto, String corpoHtml)
            throws Exception {
        enviarSmtpComConfig(SmtpConfig.fromEnv(), destinatarioEmail, assunto, corpoHtml);
    }

    static void enviarSmtpComConfig(
            SmtpConfig config, String destinatarioEmail, String assunto, String corpoHtml) throws Exception {
        if (config == null || config.host.isEmpty()) {
            throw new IllegalStateException("SMTP_HOST nao configurado.");
        }
        if (config.remetente.isEmpty()) {
            throw new IllegalStateException("SMTP_FROM / SMTP_USER nao configurado.");
        }

        Socket socket = null;
        try {
            Socket rawSocket = new Socket();
            int connectTimeout = Math.min(config.timeoutMs, 3000);
            rawSocket.connect(new InetSocketAddress(config.host, config.porta), connectTimeout);
            rawSocket.setSoTimeout(config.timeoutMs);

            if (config.usarSsl) {
                SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
                SSLSocket sslSocket = (SSLSocket) sslFactory.createSocket(rawSocket, config.host, config.porta, true);
                sslSocket.startHandshake();
                socket = sslSocket;
            } else {
                socket = rawSocket;
            }
            socket.setSoTimeout(config.timeoutMs);

            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            OutputStream saida = socket.getOutputStream();

            String resposta = lerResposta(leitor);
            if (!resposta.startsWith("220")) {
                throw new Exception("Servidor SMTP nao respondeu com 220: " + resposta);
            }

            escreverLinhaSmtp(saida, "EHLO agmrm.local");
            resposta = lerRespostaMultipla(leitor);

            if (!config.usarSsl && resposta.toUpperCase(Locale.ROOT).contains("STARTTLS")) {
                escreverLinhaSmtp(saida, "STARTTLS");
                resposta = lerResposta(leitor);
                if (!resposta.startsWith("220")) {
                    throw new Exception("STARTTLS rejeitado: " + resposta);
                }
                SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
                socket = sslFactory.createSocket(socket, config.host, config.porta, true);
                socket.setSoTimeout(config.timeoutMs);
                leitor = new BufferedReader(
                        new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
                saida = socket.getOutputStream();

                escreverLinhaSmtp(saida, "EHLO agmrm.local");
                resposta = lerRespostaMultipla(leitor);
            }

            if (!config.usuario.isEmpty() && !config.senha.isEmpty()) {
                autenticarSmtp(leitor, saida, resposta, config.usuario, config.senha);
            }

            escreverLinhaSmtp(saida, "MAIL FROM:<" + config.remetente + ">");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("MAIL FROM rejeitado: " + resposta);
            }

            escreverLinhaSmtp(saida, "RCPT TO:<" + destinatarioEmail + ">");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("RCPT TO rejeitado: " + resposta);
            }

            escreverLinhaSmtp(saida, "DATA");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("354")) {
                throw new Exception("DATA rejeitado: " + resposta);
            }

            escreverLinhaSmtp(saida, "From: AGMRM <" + config.remetente + ">");
            escreverLinhaSmtp(saida, "To: " + destinatarioEmail);
            escreverLinhaSmtp(saida, "Subject: " + codificarSubjectRFC2047(assunto));
            escreverLinhaSmtp(saida, "MIME-Version: 1.0");
            escreverLinhaSmtp(saida, "Content-Type: text/html; charset=UTF-8");
            escreverLinhaSmtp(saida, "Content-Transfer-Encoding: 8bit");
            escreverLinhaSmtp(saida, "X-Mailer: AGMRM-Java-Native-SMTP");
            escreverLinhaSmtp(saida, "");
            escreverLinhaSmtp(saida, normalizarCorpoDataRfc5321(corpoHtml));
            escreverLinhaSmtp(saida, ".");

            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("Envio do email falhou: " + resposta);
            }

            // QUIT best-effort: apos 250 OK do DATA a entrega ja foi aceita pelo servidor
            try {
                escreverLinhaSmtp(saida, "QUIT");
                lerResposta(leitor);
            } catch (Exception ignored) { }

        } finally {
            if (socket != null && !socket.isClosed()) {
                try { socket.close(); } catch (Exception ignored) {}
            }
        }
    }

    private static void autenticarSmtp(
            BufferedReader leitor, OutputStream saida, String respostaEhlo, String usuario, String senha)
            throws Exception {
        String upper = respostaEhlo != null ? respostaEhlo.toUpperCase(Locale.ROOT) : "";
        if (upper.contains("AUTH") && upper.contains("LOGIN")) {
            escreverLinhaSmtp(saida, "AUTH LOGIN");
            String resp = lerResposta(leitor);
            if (!resp.startsWith("334")) {
                throw new Exception("AUTH LOGIN rejeitado: " + resp);
            }
            escreverLinhaSmtp(saida, base64Codificar(usuario));
            resp = lerResposta(leitor);
            if (!resp.startsWith("334")) {
                throw new Exception("Autenticacao SMTP interrompida: " + resp);
            }
            escreverLinhaSmtp(saida, base64Codificar(senha));
            resp = lerResposta(leitor);
            if (!resp.startsWith("235")) {
                throw new Exception("Autenticacao SMTP falhou: " + resp);
            }
            return;
        }
        if (upper.contains("AUTH") && upper.contains("PLAIN")) {
            String credencial = "\0" + usuario + "\0" + senha;
            escreverLinhaSmtp(saida, "AUTH PLAIN " + base64Codificar(credencial));
            String resp = lerResposta(leitor);
            if (!resp.startsWith("235")) {
                throw new Exception("Autenticacao SMTP PLAIN falhou: " + resp);
            }
        }
    }

    private static void escreverLinhaSmtp(OutputStream saida, String linha) throws IOException {
        saida.write((linha + "\r\n").getBytes(StandardCharsets.UTF_8));
        saida.flush();
    }

    static String normalizarCorpoDataRfc5321(String corpo) {
        String texto = corpo == null ? "" : corpo.replace("\r\n", "\n").replace("\r", "\n");
        String[] linhas = texto.split("\n", -1);
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < linhas.length; i++) {
            if (i > 0) sb.append("\r\n");
            String linha = linhas[i];
            if (linha.startsWith(".")) {
                sb.append('.');
            }
            sb.append(linha);
        }
        return sb.toString();
    }

    // =========================================================================
    // SUBJECT RFC 2047 (SUPORTE A ACENTOS UTF-8)
    // =========================================================================

    /**
     * Codifica o subject do email usando RFC 2047 (MIME encoded-word).
     * Garante que acentos e caracteres especiais sejam exibidos corretamente
     * em todos os clientes de email (Gmail, Outlook, Thunderbird, etc).
     *
     * Formato: =?UTF-8?B?<Base64 do texto>?=
     */
    private static String codificarSubjectRFC2047(String texto) {
        if (texto == null || texto.isEmpty()) return "";

        // Verificar se o texto e puramente ASCII (nao precisa encoding)
        boolean apenasAscii = true;
        for (int i = 0; i < texto.length(); i++) {
            if (texto.charAt(i) > 127) {
                apenasAscii = false;
                break;
            }
        }

        if (apenasAscii) {
            return texto;
        }

        // Codificar em Base64 usando o padrao RFC 2047
        String base64 = java.util.Base64.getEncoder().encodeToString(
                texto.getBytes(StandardCharsets.UTF_8));
        return "=?UTF-8?B?" + base64 + "?=";
    }

    // =========================================================================
    // LEITURA DE RESPOSTAS SMTP
    // =========================================================================

    private static String lerResposta(BufferedReader leitor) throws Exception {
        String linha = leitor.readLine();
        if (linha == null) {
            throw new Exception("Conexao SMTP encerrada inesperadamente pelo servidor");
        }
        return linha;
    }

    private static String lerRespostaMultipla(BufferedReader leitor) throws Exception {
        StringBuilder builder = new StringBuilder();
        String linha;
        while ((linha = leitor.readLine()) != null) {
            builder.append(linha);
            // Linhas SMTP multi-linha tem hifen na 4a posicao (ex: "250-AUTH")
            // Linha final tem espaco na 4a posicao (ex: "250 OK")
            if (linha.length() >= 4 && linha.charAt(3) == ' ') {
                break;
            }
            builder.append("\n");
        }
        return builder.toString();
    }

    // =========================================================================
    // ENCODING
    // =========================================================================

    private static String base64Codificar(String texto) {
        return java.util.Base64.getEncoder().encodeToString(
                texto.getBytes(StandardCharsets.UTF_8));
    }

    // =========================================================================
    // LOGS ESTRUTURADOS
    // =========================================================================

    private static void log(String nivel, String mensagem) {
        String timestamp = LocalDateTime.now().format(LOG_FORMAT);
        String linha = String.format("[%s] [SMTP] [%s] %s", timestamp, nivel, mensagem);

        if ("ERROR".equals(nivel)) {
            System.err.println(linha);
        } else {
            System.out.println(linha);
        }
    }

    // =========================================================================
    // TEMPLATES HTML
    // =========================================================================

    private static String construirHtmlOtp(String codigo, String nome) {
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>"
                + "<body style=\"font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;\">"
                + "<div style=\"max-width: 500px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">"
                + "<h2 style=\"color: #1a73e8; margin-top: 0;\">&#128274; Verificação de Segurança</h2>"
                + "<p>Olá" + (nome != null && !nome.isEmpty() ? ", " + escaparHtml(nome) : "") + "!</p>"
                + "<p>Use o código abaixo para verificar sua identidade:</p>"
                + "<div style=\"background: #e8f0fe; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;\">"
                + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a73e8;\">"
                + escaparHtml(codigo) + "</span></div>"
                + "<p style=\"color: #666; font-size: 14px;\">Este código expira em 5 minutos. Não compartilhe com ninguém.</p>"
                + "<hr style=\"border: none; border-top: 1px solid #eee;\">"
                + "<p style=\"color: #999; font-size: 12px;\">AGMRM - Plataforma Educacional Integrada</p>"
                + "</div></body></html>";
    }

    private static String construirHtmlRecuperacao(String codigo, String nome) {
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>"
                + "<body style=\"font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;\">"
                + "<div style=\"max-width: 500px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">"
                + "<h2 style=\"color: #e65100; margin-top: 0;\">&#128273; Recuperação de Senha</h2>"
                + "<p>Olá" + (nome != null && !nome.isEmpty() ? ", " + escaparHtml(nome) : "") + "!</p>"
                + "<p>Recebemos uma solicitação para redefinir sua senha. Use o código abaixo:</p>"
                + "<div style=\"background: #fff3e0; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;\">"
                + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #e65100;\">"
                + escaparHtml(codigo) + "</span></div>"
                + "<p style=\"color: #666; font-size: 14px;\">Este código expira em 5 minutos.</p>"
                + "<p style=\"color: #999; font-size: 12px;\">Se você não solicitou, ignore este email com segurança.</p>"
                + "<hr style=\"border: none; border-top: 1px solid #eee;\">"
                + "<p style=\"color: #999; font-size: 12px;\">AGMRM - Plataforma Educacional Integrada</p>"
                + "</div></body></html>";
    }

    private static String construirHtmlBoasVindas(String nome, String identidade, String perfil, String senhaTemporaria) {
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>"
                + "<body style=\"font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;\">"
                + "<div style=\"max-width: 500px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">"
                + "<h2 style=\"color: #0f172a; margin-top: 0;\">Bem-vindo ao Portal AGMRM</h2>"
                + "<p>Olá" + (nome != null && !nome.isEmpty() ? ", " + escaparHtml(nome) : "") + "!</p>"
                + "<p>Sua conta institucional (" + escaparHtml(perfil != null ? perfil : "") + ") foi criada.</p>"
                + "<p><strong>Identidade:</strong> " + escaparHtml(identidade != null ? identidade : "") + "</p>"
                + (senhaTemporaria != null && !senhaTemporaria.isEmpty()
                        ? "<p><strong>Senha temporária:</strong> <code>" + escaparHtml(senhaTemporaria) + "</code></p>"
                        : "")
                + "<hr style=\"border: none; border-top: 1px solid #eee;\">"
                + "<p style=\"color: #999; font-size: 12px;\">AGMRM - Plataforma Educacional Integrada</p>"
                + "</div></body></html>";
    }

    private static String escaparHtml(String texto) {
        if (texto == null) return "";
        return texto.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    /**
     * Encerra o pool de threads de forma graciosa (aguarda emails em andamento antes de interromper).
     */
    public static void encerrar() {
        FILA_EMAILS.shutdown();
        try {
            if (!FILA_EMAILS.awaitTermination(10, TimeUnit.SECONDS)) {
                FILA_EMAILS.shutdownNow();
            }
        } catch (InterruptedException e) {
            FILA_EMAILS.shutdownNow();
            Thread.currentThread().interrupt();
        }
        log("INFO", "[SHUTDOWN] Pool de threads SMTP encerrado.");
    }
}
