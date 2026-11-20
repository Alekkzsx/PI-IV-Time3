// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalEnvioEmailAbstrato;
import utils.ConfigEnv;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Orquestrador resiliente de envio de e-mails da plataforma AGMRM.
 *
 * Coordena o pool assincrono e a cadeia de failover em 3 tiers:
 * - Tier 1: CanalSmtpNativo (RFC 5321 + retry + CircuitBreakerSmtp)
 * - Tier 2: CanalResendEmail -> CanalBrevoEmail -> CanalWebhookEmail (HTTPS REST)
 * - Tier 3: CanalOutboxLocal (memoria + console + MongoDB email_outbox)
 */
public final class SmtpCliente {
    private static final CircuitBreakerSmtp CIRCUIT_BREAKER = new CircuitBreakerSmtp();
    private static final CanalOutboxLocal OUTBOX_CANAL = new CanalOutboxLocal();

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

    public static final class SmtpConfig {
        public final String host;
        public final int porta;
        public final boolean usarSsl;
        public final String usuario;
        public final String senha;
        public final String remetente;
        public final int timeoutMs;

        public SmtpConfig(String host, int porta, boolean usarSsl, String usuario, String senha, String remetente, int timeoutMs) {
            this.host = host != null ? host.trim() : "";
            this.porta = porta;
            this.usarSsl = usarSsl;
            this.usuario = usuario != null ? usuario.trim() : "";
            this.senha = senha != null ? senha : "";
            String bruto = (remetente != null && !remetente.trim().isEmpty()) ? remetente : this.usuario;
            this.remetente = MensagemEmail.extrairEmailPuro(bruto);
            this.timeoutMs = timeoutMs > 0 ? timeoutMs : 10_000;
        }

        public static SmtpConfig fromEnv() {
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

    public static final class HttpsRelayConfig {
        public final String resendApiKey;
        public final String brevoApiKey;
        public final String webhookUrl;
        public final String remetente;

        public HttpsRelayConfig(String resendApiKey, String brevoApiKey, String webhookUrl, String remetente) {
            this.resendApiKey = resendApiKey != null ? resendApiKey.trim() : "";
            this.brevoApiKey = brevoApiKey != null ? brevoApiKey.trim() : "";
            this.webhookUrl = webhookUrl != null ? webhookUrl.trim() : "";
            String limpo = MensagemEmail.extrairEmailPuro(remetente);
            this.remetente = limpo.isEmpty() ? "portal.academico@agmrm.edu.br" : limpo;
        }

        public static HttpsRelayConfig fromEnv() {
            String usuario = ConfigEnv.obter("SMTP_USER", "");
            return new HttpsRelayConfig(
                    ConfigEnv.obter("RESEND_API_KEY", ""),
                    ConfigEnv.obter("BREVO_API_KEY", ""),
                    ConfigEnv.obter("GMAIL_WEBHOOK_URL", ""),
                    ConfigEnv.obter("SMTP_FROM", usuario)
            );
        }
    }

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

    private SmtpCliente() {}

    public static List<EmailOutboxItem> getHistoricoOutbox() {
        return CanalOutboxLocal.getHistorico();
    }

    public static String getEstadoCircuito() {
        return CIRCUIT_BREAKER.getEstado();
    }

    public static void resetarCircuitoParaTeste() {
        CIRCUIT_BREAKER.resetar();
    }

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

    // =========================================================================
    // API PUBLICA DE DISPARO ASSINCRONO E SINCRONO
    // =========================================================================

    public static void enviarOtp(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        enviarOtpComResultado(destinatarioEmail, codigoOTP, nomeUsuario);
    }

    public static CompletableFuture<ResultadoEnvioEmail> enviarOtpComResultado(
            String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String html = new TemplateEmailOtp(nomeUsuario, codigoOTP).renderizar();
        return enviarAsyncDetalhado(destinatarioEmail, "Seu código de verificação - AGMRM", html, "OTP");
    }

    public static void enviarBoasVindas(
            String destinatarioEmail, String nomeUsuario, String identidade, String perfil, String senhaTemporaria) {
        enviarBoasVindasComResultado(destinatarioEmail, nomeUsuario, identidade, perfil, senhaTemporaria);
    }

    public static CompletableFuture<ResultadoEnvioEmail> enviarBoasVindasComResultado(
            String destinatarioEmail, String nomeUsuario, String identidade, String perfil, String senhaTemporaria) {
        if (destinatarioEmail == null || destinatarioEmail.trim().isEmpty()) {
            return CompletableFuture.completedFuture(
                    new ResultadoEnvioEmail("OUTBOX", false, Collections.singletonList("Destinatario vazio"), 0L));
        }
        String html = new TemplateEmailBoasVindas(nomeUsuario, identidade, perfil, senhaTemporaria).renderizar();
        return enviarAsyncDetalhado(destinatarioEmail.trim(),
                "Bem-vindo ao Portal AGMRM — Credenciais de Acesso", html, "WELCOME");
    }

    public static void enviarRecuperacao(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        enviarRecuperacaoComResultado(destinatarioEmail, codigoOTP, nomeUsuario);
    }

    public static CompletableFuture<ResultadoEnvioEmail> enviarRecuperacaoComResultado(
            String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String html = new TemplateEmailRecuperacao(nomeUsuario, codigoOTP).renderizar();
        return enviarAsyncDetalhado(destinatarioEmail, "Recuperação de senha - AGMRM", html, "RECOVERY");
    }

    public static CompletableFuture<Void> enviarAsync(
            String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return enviarAsyncDetalhado(destinatarioEmail, assunto, corpoHtml, tipo).thenApply(r -> null);
    }

    public static CompletableFuture<ResultadoEnvioEmail> enviarAsyncDetalhado(
            String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return CompletableFuture.supplyAsync(() -> {
            int maxTentativas = Math.max(1, ConfigEnv.obterInteiro("SMTP_MAX_RETRIES", 1));
            return despacharResiliente(
                    SmtpConfig.fromEnv(),
                    HttpsRelayConfig.fromEnv(),
                    destinatarioEmail,
                    assunto,
                    corpoHtml,
                    tipo,
                    maxTentativas,
                    "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"))
            );
        }, FILA_EMAILS);
    }

    public static void enviarSincrono(String destinatarioEmail, String assunto, String corpoHtml) throws Exception {
        CanalSmtpNativo.enviarViaSocket(SmtpConfig.fromEnv(), destinatarioEmail, assunto, corpoHtml);
    }

    public static String enviarSincronoResiliente(String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        return enviarSincronoDetalhado(destinatarioEmail, assunto, corpoHtml, tipo).getCanal();
    }

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
    // ORQUESTRACAO DOS 3 TIERS DE RESILIENCIA
    // =========================================================================

    public static ResultadoEnvioEmail despacharResiliente(
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
        MensagemEmail mensagem = new MensagemEmail(destinatario, assunto, html, tipo);

        if (sandboxMode) {
            CanalEnvioEmailAbstrato.log("INFO", "[SANDBOX] Email simulado para: " + destinatario + " | Tipo: " + tipo);
            errorTrail.add("Modo sandbox ativo (SMTP_SANDBOX_MODE=true)");
            OUTBOX_CANAL.tentarEnviar(mensagem, errorTrail);
            if ("true".equalsIgnoreCase(ConfigEnv.obter("SMTP_LOG_HTML", "false"))) {
                CanalEnvioEmailAbstrato.log("DEBUG", "[SANDBOX] Assunto: " + assunto + "\n" + html);
            }
            return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
        }

        // Tier 1: SMTP nativo com Circuit Breaker
        CanalSmtpNativo canalSmtp = new CanalSmtpNativo(smtpConfig, CIRCUIT_BREAKER, maxTentativasSmtp);
        if (canalSmtp.tentarEnviar(mensagem, errorTrail)) {
            CanalOutboxLocal.registrarNoHistorico(mensagem, "SMTP");
            return new ResultadoEnvioEmail("SMTP", true, errorTrail, System.currentTimeMillis() - inicioTotal);
        }
        if (canalSmtp.foiInterrompido()) {
            OUTBOX_CANAL.tentarEnviar(mensagem, errorTrail);
            return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
        }

        // Tier 2: Cadeia HTTPS REST (Resend -> Brevo -> Webhook)
        CanalEnvioEmailAbstrato.log("WARN", "[SMTP INDISPONIVEL] Acionando Tier 2 (HTTPS REST) para " + destinatario + "...");
        String canalHttps = acionarFallbackHttps(httpsConfig, destinatario, assunto, html, tipo, errorTrail);
        if (canalHttps != null) {
            CanalOutboxLocal.registrarNoHistorico(mensagem, canalHttps);
            return new ResultadoEnvioEmail(canalHttps, true, errorTrail, System.currentTimeMillis() - inicioTotal);
        }

        // Tier 3: Outbox local (zero crash)
        CanalEnvioEmailAbstrato.log("INFO", "[RESILIENCIA ATIVA] Acionando Tier 3 (Outbox Local de Seguranca)...");
        OUTBOX_CANAL.tentarEnviar(mensagem, errorTrail);
        return new ResultadoEnvioEmail("OUTBOX", false, errorTrail, System.currentTimeMillis() - inicioTotal);
    }

    public static String acionarFallbackHttps(
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
        List<CanalEnvioEmailAbstrato> canais = Arrays.<CanalEnvioEmailAbstrato>asList(
                new CanalResendEmail(config.resendApiKey, config.remetente),
                new CanalBrevoEmail(config.brevoApiKey, config.remetente),
                new CanalWebhookEmail(config.webhookUrl, config.remetente)
        );
        MensagemEmail mensagem = new MensagemEmail(destinatario, assunto, html, tipo);
        boolean algumConfigurado = false;
        for (CanalEnvioEmailAbstrato canal : canais) {
            if (canal.estaConfigurado()) {
                algumConfigurado = true;
                if (canal.tentarEnviar(mensagem, errorTrail)) {
                    return canal.getNomeCanal();
                }
            }
        }
        if (!algumConfigurado) {
            errorTrail.add("Nenhum provedor HTTPS configurado (RESEND_API_KEY, BREVO_API_KEY, GMAIL_WEBHOOK_URL ausentes)");
        }
        return null;
    }

    // Helpers estaticos delegados (compatibilidade direta com SmtpClienteTeste)
    public static void enviarSmtpComConfig(SmtpConfig config, String destinatario, String assunto, String html) throws Exception {
        CanalSmtpNativo.enviarViaSocket(config, destinatario, assunto, html);
    }

    public static String validarRespostaWebhook(int status, String body) {
        return CanalWebhookEmail.validarRespostaWebhook(status, body);
    }

    public static String extrairEmailPuro(String valor) {
        return MensagemEmail.extrairEmailPuro(valor);
    }

    public static String normalizarCorpoDataRfc5321(String corpo) {
        return CanalSmtpNativo.normalizarCorpoDataRfc5321(corpo);
    }

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
        CanalEnvioEmailAbstrato.log("INFO", "[SHUTDOWN] Pool de threads SMTP encerrado.");
    }
}
