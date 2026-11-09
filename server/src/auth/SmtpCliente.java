// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import utils.ConfigEnv;
import utils.Json;

import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
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

    private SmtpCliente() {}

    // =========================================================================
    // API PUBLICA - ENVIO ASSINCRONO
    // =========================================================================

    /**
     * Envia um email com codigo OTP para o usuario (assincrono, nao bloqueia).
     *
     * @param destinatarioEmail Email do destinatario.
     * @param codigoOTP         Codigo OTP de 6 digitos.
     * @param nomeUsuario       Nome de exibicao do usuario.
     */
    public static void enviarOtp(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String assunto = "Seu código de verificação - AGMRM";
        String corpoHtml = construirHtmlOtp(codigoOTP, nomeUsuario);
        enviarAsync(destinatarioEmail, assunto, corpoHtml, "OTP");
    }

    /**
     * Envia um email de recuperacao de senha (assincrono, nao bloqueia).
     *
     * @param destinatarioEmail Email do destinatario.
     * @param codigoOTP         Codigo OTP de recuperacao.
     * @param nomeUsuario       Nome de exibicao do usuario.
     */
    public static void enviarRecuperacao(String destinatarioEmail, String codigoOTP, String nomeUsuario) {
        String assunto = "Recuperação de senha - AGMRM";
        String corpoHtml = construirHtmlRecuperacao(codigoOTP, nomeUsuario);
        enviarAsync(destinatarioEmail, assunto, corpoHtml, "RECOVERY");
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

        return CompletableFuture.runAsync(() -> {
            enviarComRetry(destinatarioEmail, assunto, corpoHtml, tipo);
        }, FILA_EMAILS);
    }

    /**
     * Envia um email de forma sincrona (bloqueia ate concluir ou falhar).
     * Usado principalmente em testes.
     */
    public static void enviarSincrono(String destinatarioEmail, String assunto, String corpoHtml) throws Exception {
        enviarSmtp(destinatarioEmail, assunto, corpoHtml);
    }

    /**
     * Envia um email de forma sincrona percorrendo todos os 3 tiers de resiliencia (SMTP -> Webhook -> Outbox).
     * Retorna o canal efetivo utilizado ("SMTP", "WEBHOOK" ou "OUTBOX").
     */
    public static String enviarSincronoResiliente(String destinatarioEmail, String assunto, String corpoHtml, String tipo) {
        try {
            enviarSmtp(destinatarioEmail, assunto, corpoHtml);
            OUTBOX_HISTORICO.offer(new EmailOutboxItem(destinatarioEmail, assunto, extrairCodigoOtp(corpoHtml), tipo, "SMTP"));
            return "SMTP";
        } catch (Exception e) {
            log("WARN", "[DIAGNOSTICO SMTP FALHOU] " + e.getMessage());
            boolean webhookOk = acionarFallbackWebhook(destinatarioEmail, assunto, corpoHtml, tipo, e);
            if (webhookOk) {
                return "WEBHOOK";
            }
            acionarLocalOutbox(destinatarioEmail, assunto, corpoHtml, tipo);
            return "OUTBOX";
        }
    }

    // =========================================================================
    // LOGICA DE RETRY COM BACKOFF EXPONENCIAL
    // =========================================================================

    private static void enviarComRetry(String destinatario, String assunto, String html, String tipo) {
        // Modo sandbox: armazena no outbox e exibe no console sem disparar externamente
        if ("true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"))) {
            log("INFO", "[SANDBOX] Email simulado para: " + destinatario + " | Tipo: " + tipo);
            acionarLocalOutbox(destinatario, assunto, html, tipo);
            if ("true".equalsIgnoreCase(ConfigEnv.obter("SMTP_LOG_HTML", "false"))) {
                log("DEBUG", "[SANDBOX] Assunto: " + assunto + "\n" + html);
            }
            return;
        }

        int maxTentativas = ConfigEnv.obterInteiro("SMTP_MAX_RETRIES", 2);
        long delayMs = 1000; // 1s, 2s
        Exception ultimaExcecao = null;

        for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
            try {
                long inicio = System.currentTimeMillis();
                enviarSmtp(destinatario, assunto, html);
                long latencia = System.currentTimeMillis() - inicio;
                log("INFO", "[ENVIO OK] Tipo=" + tipo + " | Para=" + destinatario
                        + " | Tentativa=" + tentativa + "/" + maxTentativas
                        + " | Latencia=" + latencia + "ms");
                OUTBOX_HISTORICO.offer(new EmailOutboxItem(destinatario, assunto, extrairCodigoOtp(html), tipo, "SMTP"));
                return; // Sucesso!
            } catch (Exception e) {
                ultimaExcecao = e;
                log("WARN", "[FALHA SMTP] Tipo=" + tipo + " | Para=" + destinatario
                        + " | Tentativa=" + tentativa + "/" + maxTentativas
                        + " | Erro: " + e.getMessage());

                if (tentativa < maxTentativas) {
                    try {
                        Thread.sleep(delayMs);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        log("ERROR", "[INTERRUPCAO] Retry interrompido para " + destinatario);
                        acionarLocalOutbox(destinatario, assunto, html, tipo);
                        return;
                    }
                    delayMs *= 2; // Backoff exponencial
                }
            }
        }

        // Tier 1 SMTP falhou - tentar Tier 2 Webhook HTTPS
        log("WARN", "[SMTP ESGOTADO] Tentativas SMTP falharam para " + destinatario + ". Acionando Tier 2 (Webhook HTTPS)...");
        boolean webhookOk = acionarFallbackWebhook(destinatario, assunto, html, tipo, ultimaExcecao);

        // Se Webhook tambem falhar ou nao estiver disponivel, acionar Tier 3 (Outbox Local)
        if (!webhookOk) {
            log("INFO", "[RESILIENCIA ATIVA] Acionando Tier 3 (Outbox Local de Seguranca)...");
            acionarLocalOutbox(destinatario, assunto, html, tipo);
        }
    }

    // =========================================================================
    // FALLBACK: WEBHOOK HTTP (Google Apps Script / Relay REST na Porta 443)
    // =========================================================================

    private static boolean acionarFallbackWebhook(String destinatario, String assunto,
                                                   String html, String tipo, Exception causa) {
        String webhookUrl = ConfigEnv.obter("GMAIL_WEBHOOK_URL", "");

        if (webhookUrl == null || webhookUrl.trim().isEmpty()) {
            log("INFO", "[SEM WEBHOOK] GMAIL_WEBHOOK_URL nao configurado.");
            return false;
        }

        try {
            URL url = new URL(webhookUrl.trim());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("User-Agent", "AGMRM-Native-Server/1.0");
            conn.setDoOutput(true);
            conn.setConnectTimeout(6000);
            conn.setReadTimeout(6000);

            // Construir payload JSON no formato compativel com Google Apps Script
            String payload = String.format(
                    "{\"to\":\"%s\",\"subject\":\"%s\",\"html\":%s,\"text\":\"%s\",\"type\":\"%s\"}",
                    escaparJson(destinatario),
                    escaparJson(assunto),
                    Json.escrever(html),
                    escaparJson(assunto),
                    escaparJson(tipo)
            );

            OutputStream os = conn.getOutputStream();
            os.write(payload.getBytes(StandardCharsets.UTF_8));
            os.flush();
            os.close();

            int status = conn.getResponseCode();

            // Lidar com redirecionamento 302/303 comum no Google Apps Script
            if (status == HttpURLConnection.HTTP_MOVED_TEMP || status == HttpURLConnection.HTTP_SEE_OTHER) {
                String redirectUrl = conn.getHeaderField("Location");
                if (redirectUrl != null && !redirectUrl.isEmpty()) {
                    conn.disconnect();
                    URL nextUrl = new URL(redirectUrl);
                    conn = (HttpURLConnection) nextUrl.openConnection();
                    conn.setRequestMethod("GET");
                    conn.setConnectTimeout(6000);
                    conn.setReadTimeout(6000);
                    status = conn.getResponseCode();
                }
            }

            // Ler resposta para verificar se nao e pagina de erro HTML (ex: 404 Google Drive)
            BufferedReader reader = new BufferedReader(new InputStreamReader(
                    status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream(),
                    StandardCharsets.UTF_8
            ));
            StringBuilder body = new StringBuilder();
            String linha;
            while ((linha = reader.readLine()) != null) {
                body.append(linha);
            }
            reader.close();
            conn.disconnect();

            String respostaTexto = body.toString();
            if (status >= 200 && status < 300 && !respostaTexto.contains("errorMessage")
                    && !respostaTexto.contains("Não foi possível abrir o arquivo")) {
                log("INFO", "[FALLBACK OK] Webhook enviado com sucesso para " + destinatario + " | HTTP " + status);
                OUTBOX_HISTORICO.offer(new EmailOutboxItem(destinatario, assunto, extrairCodigoOtp(html), tipo, "WEBHOOK"));
                return true;
            } else {
                log("WARN", "[FALLBACK REJEITADO] Webhook retornou HTTP " + status + " com conteudo nao reconhecido.");
                return false;
            }

        } catch (Exception e) {
            log("WARN", "[FALLBACK FALHOU] Falha ao contatar Webhook: " + e.getMessage());
            return false;
        }
    }

    // =========================================================================
    // TIER 3: LOCAL OUTBOX (RESILIENCIA TOTAL EM CONSOLE E MEMORIA)
    // =========================================================================

    private static void acionarLocalOutbox(String destinatario, String assunto, String html, String tipo) {
        String codigoOtp = extrairCodigoOtp(html);
        EmailOutboxItem item = new EmailOutboxItem(destinatario, assunto, codigoOtp, tipo, "OUTBOX");
        OUTBOX_HISTORICO.offer(item);
        while (OUTBOX_HISTORICO.size() > 50) {
            OUTBOX_HISTORICO.poll();
        }

        String destinatarioFormatado = truncar(destinatario, 56);
        String assuntoFormatado = truncar(assunto, 56);
        String otpFormatado = codigoOtp != null ? codigoOtp : "------";

        String moldura = "\n"
                + "┌════════════════════════════════════════════════════════════════════┐\n"
                + "│ 📬 [OUTBOX LOCAL / RESILIÊNCIA ATIVA]                               │\n"
                + String.format("│ Para:    %-58s │\n", destinatarioFormatado)
                + String.format("│ Assunto: %-58s │\n", assuntoFormatado)
                + "│                                                                    │\n"
                + String.format("│   CÓDIGO DE VERIFICAÇÃO OTP:  [ %-6s ]                           │\n", otpFormatado)
                + "│                                                                    │\n"
                + "└════════════════════════════════════════════════════════════════════┘\n";

        System.out.println(moldura);
        log("INFO", "[OUTBOX REGISTRADO] Email retido em outbox local para " + destinatario + " | OTP=" + otpFormatado);
    }

    private static String extrairCodigoOtp(String html) {
        if (html == null) return null;
        Matcher m = OTP_PATTERN.matcher(html);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }

    private static String truncar(String texto, int max) {
        if (texto == null) return "";
        if (texto.length() <= max) return texto;
        return texto.substring(0, max - 3) + "...";
    }

    // =========================================================================
    // PROTOCOLO SMTP (RFC 5321) - IMPLEMENTACAO NA UNHA COM FAIL-FAST
    // =========================================================================

    private static void enviarSmtp(String destinatarioEmail, String assunto, String corpoHtml)
            throws Exception {

        String host = ConfigEnv.obter("SMTP_HOST", "");
        int porta = ConfigEnv.obterInteiro("SMTP_PORT", 587);
        boolean usarSsl = "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SECURE", "false"))
                || "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SSL", "false"));
        String usuario = ConfigEnv.obter("SMTP_USER", "");
        String senha = ConfigEnv.obter("SMTP_PASSWORD", "");
        String remetente = ConfigEnv.obter("SMTP_FROM", usuario);
        int timeoutMs = ConfigEnv.obterInteiro("SMTP_TIMEOUT_MS", 10000);

        if (host.isEmpty()) {
            log("WARN", "[SIMULACAO] SMTP_HOST nao configurado. Email nao enviado para: "
                    + destinatarioEmail);
            log("INFO", "[SIMULACAO] Assunto: " + assunto);
            return;
        }

        Socket socket = null;
        try {
            // 1. Conectar ao servidor SMTP com fail-fast (max 3000ms de connect timeout)
            Socket rawSocket = new Socket();
            int connectTimeout = Math.min(timeoutMs, 3000);
            rawSocket.connect(new InetSocketAddress(host, porta), connectTimeout);
            rawSocket.setSoTimeout(timeoutMs);

            if (usarSsl) {
                SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
                SSLSocket sslSocket = (SSLSocket) sslFactory.createSocket(rawSocket, host, porta, true);
                sslSocket.startHandshake();
                socket = sslSocket;
            } else {
                socket = rawSocket;
            }
            socket.setSoTimeout(timeoutMs);

            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            OutputStream saida = socket.getOutputStream();
            PrintWriter escritor = new PrintWriter(saida, true);

            // 2. Ler saudacao do servidor
            String resposta = lerResposta(leitor);
            if (!resposta.startsWith("220")) {
                throw new Exception("Servidor SMTP nao respondeu com 220: " + resposta);
            }

            // 3. EHLO
            escritor.println("EHLO agmrm.local");
            resposta = lerRespostaMultipla(leitor);

            // 4. STARTTLS se disponivel e SSL nao esta ativo
            if (!usarSsl && resposta.contains("STARTTLS")) {
                escritor.println("STARTTLS");
                resposta = lerResposta(leitor);
                if (resposta.startsWith("220")) {
                    SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
                    socket = sslFactory.createSocket(socket, host, porta, true);
                    socket.setSoTimeout(timeoutMs);
                    leitor = new BufferedReader(
                            new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
                    saida = socket.getOutputStream();
                    escritor = new PrintWriter(saida, true);

                    escritor.println("EHLO agmrm.local");
                    resposta = lerRespostaMultipla(leitor);
                }
            }

            // 5. Autenticacao
            if (!usuario.isEmpty() && !senha.isEmpty()) {
                if (resposta.contains("AUTH") && resposta.contains("LOGIN")) {
                    escritor.println("AUTH LOGIN");
                    resposta = lerResposta(leitor);
                    if (resposta.startsWith("334")) {
                        escritor.println(base64Codificar(usuario));
                        resposta = lerResposta(leitor);
                        if (resposta.startsWith("334")) {
                            escritor.println(base64Codificar(senha));
                            resposta = lerResposta(leitor);
                            if (!resposta.startsWith("235")) {
                                throw new Exception("Autenticacao SMTP falhou: " + resposta);
                            }
                        } else {
                            throw new Exception("Autenticacao SMTP interrompida: " + resposta);
                        }
                    }
                }
            }

            // 6. MAIL FROM
            escritor.println("MAIL FROM:<" + remetente + ">");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("MAIL FROM rejeitado: " + resposta);
            }

            // 7. RCPT TO
            escritor.println("RCPT TO:<" + destinatarioEmail + ">");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("RCPT TO rejeitado: " + resposta);
            }

            // 8. DATA
            escritor.println("DATA");
            resposta = lerResposta(leitor);
            if (!resposta.startsWith("354")) {
                throw new Exception("DATA rejeitado: " + resposta);
            }

            // 9. Enviar corpo do email
            escritor.println("From: AGMRM <" + remetente + ">");
            escritor.println("To: " + destinatarioEmail);
            escritor.println("Subject: " + codificarSubjectRFC2047(assunto));
            escritor.println("MIME-Version: 1.0");
            escritor.println("Content-Type: text/html; charset=UTF-8");
            escritor.println("Content-Transfer-Encoding: 8bit");
            escritor.println("X-Mailer: AGMRM-Java-Native-SMTP");
            escritor.println("");
            escritor.println(corpoHtml);
            escritor.println(".");
            escritor.flush();

            resposta = lerResposta(leitor);
            if (!resposta.startsWith("250")) {
                throw new Exception("Envio do email falhou: " + resposta);
            }

            // 10. QUIT
            escritor.println("QUIT");
            lerResposta(leitor);

        } finally {
            if (socket != null && !socket.isClosed()) {
                try { socket.close(); } catch (Exception ignored) {}
            }
        }
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

    private static String escaparJson(String texto) {
        if (texto == null) return "";
        return texto.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
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

    private static String escaparHtml(String texto) {
        if (texto == null) return "";
        return texto.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    /**
     * Encerra o pool de threads de forma gracios (aguarda emails em andamento).
     */
    public static void encerrar() {
        FILA_EMAILS.shutdown();
        log("INFO", "[SHUTDOWN] Pool de threads SMTP encerrado.");
    }
}
