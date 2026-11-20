// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package auth;

import auth.modules.email.SmtpCliente;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Testes unitarios offline do cliente SMTP nativo (RFC 5321 CRLF, dot-stuffing,
 * AUTH LOGIN/PLAIN, sanitizacao de SMTP_FROM, validacao de Webhook e Circuit Breaker).
 * Usa servidores MOCK em ServerSocket local (porta efemera) que capturam a transcricao
 * byte a byte do dialogo - nenhum servidor de e-mail real e contatado.
 */
public class SmtpClienteTeste {
    private static int falhas = 0;

    /** Assertiva simples: imprime [OK]/[FALHA] e acumula o contador de falhas. */
    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    /** Executa os 6 blocos de cenario; devolve o numero de falhas (0 = tudo passou). */
    public static int executar() {
        falhas = 0;
        SmtpCliente.resetarCircuitoParaTeste();
        try {
            testarExtracaoEmailESanitizerData();
            testarValidacaoWebhook();
            testarSmtpCrlfAuthLoginESender();
            testarSmtpAuthPlainEQuitFechado();
            testarFallbackWebhookERedirect302();
            testarHttp500SemCorpoECircuitBreaker();
        } catch (Exception e) {
            esperar(false, "SmtpClienteTeste sem excecoes inesperadas: " + e.getMessage());
        } finally {
            SmtpCliente.resetarCircuitoParaTeste();
        }
        return falhas;
    }

    /** Parser de endereco "Nome <email>" e normalizacao DATA (LF->CRLF + dot-stuffing). */
    private static void testarExtracaoEmailESanitizerData() {
        esperar("staff@agmrm.edu.br".equals(SmtpCliente.extrairEmailPuro("Portal AGMRM <staff@agmrm.edu.br>")),
                "SmtpCliente: extrai endereco puro de SMTP_FROM com nome de exibicao");
        esperar("puro@agmrm.edu.br".equals(SmtpCliente.extrairEmailPuro("  puro@agmrm.edu.br  ")),
                "SmtpCliente: preserva SMTP_FROM quando ja e endereco puro");

        String data = SmtpCliente.normalizarCorpoDataRfc5321("linha1\n.linha2\r\nlinha3");
        esperar("linha1\r\n..linha2\r\nlinha3".equals(data),
                "SmtpCliente: normaliza LF para CRLF e aplica dot-stuffing na RFC 5321");
    }

    /** Validacao rigorosa do webhook: 200 com erro logico/HTML tambem e rejeitado. */
    private static void testarValidacaoWebhook() {
        esperar(SmtpCliente.validarRespostaWebhook(200, "{\"status\":200,\"success\":true}") == null,
                "Webhook: aceita HTTP 200 com JSON {status:200, success:true}");
        esperar(SmtpCliente.validarRespostaWebhook(200, "{\"status\":500,\"error\":\"Daily limit exceeded\"}") != null,
                "Webhook: rejeita HTTP 200 quando JSON traz status=500 e campo error");
        esperar(SmtpCliente.validarRespostaWebhook(200, "{\"ok\":false}") != null,
                "Webhook: rejeita HTTP 200 quando JSON traz ok=false");
        esperar(SmtpCliente.validarRespostaWebhook(200, "<!DOCTYPE html><html><body>Erro</body></html>") != null,
                "Webhook: rejeita pagina HTML de erro devolvida com HTTP 200");
        esperar(SmtpCliente.validarRespostaWebhook(502, "") != null,
                "Webhook: rejeita HTTP 502 com corpo vazio");
    }

    /**
     * Mock SMTP com AUTH LOGIN: captura o dialogo inteiro e exige CRLF estrito em TODAS
     * as linhas (bare LF quebraria servidores rigidos), MAIL FROM sem nome de exibicao
     * e DATA terminado em <CRLF>.<CRLF> com dot-stuffing.
     */
    private static void testarSmtpCrlfAuthLoginESender() throws Exception {
        final ServerSocket server = new ServerSocket(0, 5, InetAddress.getByName("127.0.0.1"));
        final AtomicReference<String> transcript = new AtomicReference<String>("");
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                Socket client = null;
                try {
                    client = server.accept();
                    OutputStream out = client.getOutputStream();
                    InputStream in = client.getInputStream();
                    ByteArrayOutputStream captured = new ByteArrayOutputStream();
                    escrever(out, "220 mock.smtp.local ESMTP\r\n");

                    String ehlo = lerLinhaBruta(in, captured);
                    if (ehlo.startsWith("EHLO")) {
                        escrever(out, "250-mock.smtp.local\r\n250 AUTH LOGIN\r\n");
                    }
                    if (lerLinhaBruta(in, captured).equals("AUTH LOGIN\r\n")) {
                        escrever(out, "334 VXNlcm5hbWU6\r\n");
                        lerLinhaBruta(in, captured); // user
                        escrever(out, "334 UGFzc3dvcmQ6\r\n");
                        lerLinhaBruta(in, captured); // pass
                        escrever(out, "235 2.7.0 Authentication successful\r\n");
                    }
                    lerLinhaBruta(in, captured); // MAIL FROM
                    escrever(out, "250 2.1.0 OK\r\n");
                    lerLinhaBruta(in, captured); // RCPT TO
                    escrever(out, "250 2.1.5 OK\r\n");
                    lerLinhaBruta(in, captured); // DATA
                    escrever(out, "354 End data with <CR><LF>.<CR><LF>\r\n");

                    while (true) {
                        String line = lerLinhaBruta(in, captured);
                        if (line.equals(".\r\n") || line.isEmpty()) break;
                    }
                    escrever(out, "250 2.0.0 OK queued\r\n");
                    lerLinhaBruta(in, captured); // QUIT
                    escrever(out, "221 2.0.0 Bye\r\n");
                    transcript.set(new String(captured.toByteArray(), StandardCharsets.UTF_8));
                } catch (Exception ignored) {
                } finally {
                    try { if (client != null) client.close(); } catch (IOException ignored) { }
                    try { server.close(); } catch (IOException ignored) { }
                }
            }
        });
        t.setDaemon(true);
        t.start();

        SmtpCliente.SmtpConfig cfg = new SmtpCliente.SmtpConfig(
                "127.0.0.1", server.getLocalPort(), false, "user@test.local", "secret",
                "Portal AGMRM <remetente@test.local>", 3000);
        SmtpCliente.enviarSmtpComConfig(cfg, "destino@test.local", "Assunto Teste", "<p>Ola</p>\n.linha-com-ponto");
        t.join(3000);

        String raw = transcript.get();
        // Remove todos os CRLF legitimos; se sobrar algum '\n', havia bare LF no dialogo.
        boolean temBareLf = raw.replace("\r\n", "").contains("\n");
        esperar(!raw.isEmpty() && !temBareLf,
                "SMTP RFC 5321: todas as linhas enviadas usam estritamente CRLF (nenhum bare LF)");
        esperar(raw.contains("MAIL FROM:<remetente@test.local>\r\n"),
                "SMTP MAIL FROM: usa endereco extraido sem nome de exibicao");
        esperar(raw.contains("\r\n..linha-com-ponto\r\n.\r\n"),
                "SMTP DATA: aplica dot-stuffing e termina com <CRLF>.<CRLF>");
    }

    /** Mock SMTP so com AUTH PLAIN: valida o comando unico e a tolerancia ao QUIT sem resposta (250 ja aceitou). */
    private static void testarSmtpAuthPlainEQuitFechado() throws Exception {
        final ServerSocket server = new ServerSocket(0, 5, InetAddress.getByName("127.0.0.1"));
        final AtomicReference<String> authLine = new AtomicReference<String>("");
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                Socket client = null;
                try {
                    client = server.accept();
                    OutputStream out = client.getOutputStream();
                    InputStream in = client.getInputStream();
                    ByteArrayOutputStream captured = new ByteArrayOutputStream();
                    escrever(out, "220 mock.plain ESMTP\r\n");
                    lerLinhaBruta(in, captured); // EHLO
                    escrever(out, "250-mock.plain\r\n250 AUTH PLAIN\r\n");
                    authLine.set(lerLinhaBruta(in, captured));
                    escrever(out, "235 2.7.0 OK\r\n");
                    lerLinhaBruta(in, captured); // MAIL FROM
                    escrever(out, "250 OK\r\n");
                    lerLinhaBruta(in, captured); // RCPT TO
                    escrever(out, "250 OK\r\n");
                    lerLinhaBruta(in, captured); // DATA
                    escrever(out, "354 Go ahead\r\n");
                    while (true) {
                        String line = lerLinhaBruta(in, captured);
                        if (line.equals(".\r\n") || line.isEmpty()) break;
                    }
                    escrever(out, "250 Accepted\r\n");
                    // Fecha imediatamente sem responder QUIT
                    client.close();
                } catch (Exception ignored) {
                } finally {
                    try { if (client != null) client.close(); } catch (IOException ignored) { }
                    try { server.close(); } catch (IOException ignored) { }
                }
            }
        });
        t.setDaemon(true);
        t.start();

        SmtpCliente.SmtpConfig cfg = new SmtpCliente.SmtpConfig(
                "127.0.0.1", server.getLocalPort(), false, "u@t.local", "p123", "", 3000);
        boolean ok = true;
        try {
            SmtpCliente.enviarSmtpComConfig(cfg, "dest@t.local", "Teste Plain", "<b>Corpo</b>");
        } catch (Exception e) {
            ok = false;
        }
        t.join(3000);

        esperar(ok && authLine.get().startsWith("AUTH PLAIN "),
                "SMTP AUTH PLAIN & QUIT: autentica via AUTH PLAIN e tolera fechamento imediato apos 250 OK");
    }

    /**
     * Cadeia completa: SMTP desconfigurado + webhook que responde 302 -> GET com JSON
     * de erro logico. Exige OUTBOX (nao entregue) e a causa exata preservada no errorTrail.
     */
    private static void testarFallbackWebhookERedirect302() throws Exception {
        final ServerSocket httpServer = new ServerSocket(0, 5, InetAddress.getByName("127.0.0.1"));
        final int port = httpServer.getLocalPort();
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    // 1a conexao: POST /exec -> 302 Location /echo
                    Socket s1 = httpServer.accept();
                    lerRequisicaoHttp(s1.getInputStream());
                    escrever(s1.getOutputStream(),
                            "HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:" + port + "/echo\r\nContent-Length: 0\r\n\r\n");
                    s1.close();

                    // 2a conexao: GET /echo -> HTTP 200 mas corpo JSON com erro do Apps Script
                    Socket s2 = httpServer.accept();
                    lerRequisicaoHttp(s2.getInputStream());
                    String errJson = "{\"status\":500,\"error\":\"Exception: Daily quota exceeded\"}";
                    byte[] bytes = errJson.getBytes(StandardCharsets.UTF_8);
                    escrever(s2.getOutputStream(),
                            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "
                                    + bytes.length + "\r\n\r\n" + errJson);
                    s2.close();
                } catch (Exception ignored) {
                } finally {
                    try { httpServer.close(); } catch (IOException ignored) { }
                }
            }
        });
        t.setDaemon(true);
        t.start();

        SmtpCliente.SmtpConfig semSmtp = new SmtpCliente.SmtpConfig("", 465, true, "", "", "", 1000);
        SmtpCliente.HttpsRelayConfig https = new SmtpCliente.HttpsRelayConfig(
                "", "", "http://127.0.0.1:" + port + "/exec", "noreply@agmrm.test");

        SmtpCliente.ResultadoEnvioEmail res = SmtpCliente.despacharResiliente(
                semSmtp, https, "aluno@agmrm.test", "Teste", "<p>123456</p>", "OTP", 1, false);
        t.join(3000);

        esperar("OUTBOX".equals(res.getCanal()) && !res.isDeliveredExternally(),
                "Resiliencia: SMTP vazio + Webhook retornando {status:500,error} cai em OUTBOX com deliveredExternally=false");
        esperar(res.getErrorTrail().size() >= 2
                        && res.getErrorTrail().get(1).contains("Daily quota exceeded"),
                "Resiliencia: errorTrail preserva a causa exata retornada pelo Webhook");
    }

    /** HTTP 500 com corpo vazio nao pode NPE; depois, 3 falhas SMTP abrem o breaker e o proximo envio pula o tier. */
    private static void testarHttp500SemCorpoECircuitBreaker() throws Exception {
        final ServerSocket httpServer = new ServerSocket(0, 5, InetAddress.getByName("127.0.0.1"));
        final int port = httpServer.getLocalPort();
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    Socket s = httpServer.accept();
                    lerRequisicaoHttp(s.getInputStream());
                    escrever(s.getOutputStream(), "HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n");
                    s.close();
                } catch (Exception ignored) {
                } finally {
                    try { httpServer.close(); } catch (IOException ignored) { }
                }
            }
        });
        t.setDaemon(true);
        t.start();

        List<String> trail = new ArrayList<String>();
        SmtpCliente.HttpsRelayConfig httpsErr = new SmtpCliente.HttpsRelayConfig(
                "", "", "http://127.0.0.1:" + port + "/exec", "noreply@agmrm.test");
        String canal = SmtpCliente.acionarFallbackHttps(httpsErr, "a@b.com", "Assunto", "<p>x</p>", "OTP", trail);
        t.join(3000);

        esperar(canal == null && !trail.isEmpty() && trail.get(0).contains("HTTP 500"),
                "Webhook HTTP 500 sem corpo: nao lanca NullPointerException e registra HTTP 500 no errorTrail");

        // Testar Circuit Breaker com porta fechada
        SmtpCliente.resetarCircuitoParaTeste();
        ServerSocket portaLivre = new ServerSocket(0, 1, InetAddress.getByName("127.0.0.1"));
        int portaFechada = portaLivre.getLocalPort();
        portaLivre.close();

        SmtpCliente.SmtpConfig smtpQuebrado = new SmtpCliente.SmtpConfig(
                "127.0.0.1", portaFechada, false, "", "", "noreply@agmrm.test", 500);
        SmtpCliente.HttpsRelayConfig semHttps = new SmtpCliente.HttpsRelayConfig("", "", "", "");

        SmtpCliente.despacharResiliente(smtpQuebrado, semHttps, "a@b.com", "T", "<p>111111</p>", "OTP", 3, false);
        esperar("OPEN".equals(SmtpCliente.getEstadoCircuito()),
                "Circuit Breaker: abre apos 3 falhas consecutivas de SMTP");

        SmtpCliente.ResultadoEnvioEmail aposAberto = SmtpCliente.despacharResiliente(
                smtpQuebrado, semHttps, "a@b.com", "T", "<p>222222</p>", "OTP", 1, false);
        esperar(!aposAberto.getErrorTrail().isEmpty()
                        && aposAberto.getErrorTrail().get(0).contains("Circuit Breaker OPEN"),
                "Circuit Breaker: pula SMTP imediatamente enquanto OPEN e registra no errorTrail");
    }

    /** Escreve texto cru no socket do mock (respostas SMTP/HTTP ja vem com CRLF). */
    private static void escrever(OutputStream out, String texto) throws IOException {
        out.write(texto.getBytes(StandardCharsets.UTF_8));
        out.flush();
    }

    /** Le uma linha ate LF preservando os bytes originais no capturador (transcricao fiel). */
    private static String lerLinhaBruta(InputStream in, ByteArrayOutputStream captured) throws IOException {
        ByteArrayOutputStream line = new ByteArrayOutputStream();
        int b;
        while ((b = in.read()) != -1) {
            captured.write(b);
            line.write(b);
            if (b == '\n') break;
        }
        return new String(line.toByteArray(), StandardCharsets.UTF_8);
    }

    /** Consome uma requisicao HTTP do mock: cabecalhos ate a linha vazia + Content-Length bytes de corpo. */
    private static void lerRequisicaoHttp(InputStream in) throws IOException {
        ByteArrayOutputStream buf = new ByteArrayOutputStream();
        int b;
        int contentLength = 0;
        while ((b = in.read()) != -1) {
            buf.write(b);
            String s = new String(buf.toByteArray(), StandardCharsets.ISO_8859_1);
            if (s.endsWith("\r\n\r\n")) {
                for (String header : s.split("\r\n")) {
                    if (header.toLowerCase().startsWith("content-length:")) {
                        contentLength = Integer.parseInt(header.substring("content-length:".length()).trim());
                    }
                }
                break;
            }
        }
        for (int i = 0; i < contentLength; i++) {
            if (in.read() == -1) break;
        }
    }
}
