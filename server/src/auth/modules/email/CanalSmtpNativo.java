// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalEnvioEmailAbstrato;

import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Locale;

/**
 * Canal Tier 1: Transporte SMTP nativo (RFC 5321) sobre TCP/SSL/STARTTLS
 * com AUTH LOGIN/PLAIN, encoding RFC 2047, dot-stuffing, retry exponencial e Circuit Breaker.
 */
public class CanalSmtpNativo extends CanalEnvioEmailAbstrato {
    private final SmtpCliente.SmtpConfig config;
    private final CircuitBreakerSmtp circuitBreaker;
    private final int maxTentativas;
    private boolean interrompido = false;

    public CanalSmtpNativo(
            SmtpCliente.SmtpConfig config,
            CircuitBreakerSmtp circuitBreaker,
            int maxTentativas) {
        this.config = config;
        this.circuitBreaker = circuitBreaker;
        this.maxTentativas = Math.max(1, maxTentativas);
    }

    @Override
    public String getNomeCanal() {
        return "SMTP";
    }

    @Override
    public boolean estaConfigurado() {
        return config != null && !config.host.isEmpty() && circuitBreaker.permitirTentativa();
    }

    public boolean foiInterrompido() {
        return interrompido;
    }

    @Override
    protected void registrarNaoConfigurado(List<String> errorTrail) {
        if (errorTrail == null) {
            return;
        }
        if (config == null || config.host.isEmpty()) {
            errorTrail.add("SMTP nao configurado (SMTP_HOST vazio)");
        } else {
            errorTrail.add("Circuit Breaker OPEN: SMTP ignorado temporariamente");
        }
    }

    @Override
    protected boolean enviarInterno(MensagemEmail mensagem, List<String> errorTrail) {
        long delayMs = 1000L;
        for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
            try {
                long inicio = System.currentTimeMillis();
                enviarViaSocket(config, mensagem.getDestinatario(), mensagem.getAssunto(), mensagem.getCorpoHtml());
                long latencia = System.currentTimeMillis() - inicio;
                circuitBreaker.registrarSucesso();
                log("INFO", "[ENVIO OK] Tipo=" + mensagem.getTipo() + " | Para=" + mensagem.getDestinatario()
                        + " | Tentativa=" + tentativa + "/" + maxTentativas + " | Latencia=" + latencia + "ms");
                return true;
            } catch (Exception e) {
                String msgErro = "SMTP tentativa " + tentativa + "/" + maxTentativas + ": "
                        + (e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName());
                if (errorTrail != null) {
                    errorTrail.add(msgErro);
                }
                circuitBreaker.registrarFalha(msgErro);
                log("WARN", "[FALHA SMTP] Tipo=" + mensagem.getTipo() + " | Para=" + mensagem.getDestinatario()
                        + " | Tentativa=" + tentativa + "/" + maxTentativas + " | Erro: " + e.getMessage());

                if (circuitBreaker.estaAberto()) {
                    break;
                }
                if (tentativa < maxTentativas) {
                    try {
                        Thread.sleep(delayMs);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        interrompido = true;
                        if (errorTrail != null) {
                            errorTrail.add("Retry SMTP interrompido");
                        }
                        log("ERROR", "[INTERRUPCAO] Retry interrompido para " + mensagem.getDestinatario());
                        return false;
                    }
                    delayMs *= 2L;
                }
            }
        }
        return false;
    }

    public static void enviarViaSocket(
            SmtpCliente.SmtpConfig config,
            String destinatarioEmail,
            String assunto,
            String corpoHtml) throws Exception {
        if (config == null || config.host.isEmpty()) {
            throw new IllegalStateException("SMTP_HOST nao configurado.");
        }
        if (config.remetente.isEmpty()) {
            throw new IllegalStateException("SMTP_FROM / SMTP_USER nao configurado.");
        }

        Socket socket = null;
        try {
            socket = abrirConexao(config);
            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            OutputStream saida = socket.getOutputStream();

            exigirCodigo(lerResposta(leitor), "220", "Servidor SMTP nao respondeu com 220");

            escreverLinhaSmtp(saida, "EHLO agmrm.local");
            String respostaEhlo = lerRespostaMultipla(leitor);

            if (!config.usarSsl && respostaEhlo.toUpperCase(Locale.ROOT).contains("STARTTLS")) {
                escreverLinhaSmtp(saida, "STARTTLS");
                exigirCodigo(lerResposta(leitor), "220", "STARTTLS rejeitado");
                SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
                socket = sslFactory.createSocket(socket, config.host, config.porta, true);
                socket.setSoTimeout(config.timeoutMs);
                leitor = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
                saida = socket.getOutputStream();
                escreverLinhaSmtp(saida, "EHLO agmrm.local");
                respostaEhlo = lerRespostaMultipla(leitor);
            }

            if (!config.usuario.isEmpty() && !config.senha.isEmpty()) {
                autenticarSmtp(leitor, saida, respostaEhlo, config.usuario, config.senha);
            }

            escreverLinhaSmtp(saida, "MAIL FROM:<" + config.remetente + ">");
            exigirCodigo(lerResposta(leitor), "250", "MAIL FROM rejeitado");

            escreverLinhaSmtp(saida, "RCPT TO:<" + destinatarioEmail + ">");
            exigirCodigo(lerResposta(leitor), "250", "RCPT TO rejeitado");

            escreverLinhaSmtp(saida, "DATA");
            exigirCodigo(lerResposta(leitor), "354", "DATA rejeitado");

            escreverCabecalhosECorpo(saida, config.remetente, destinatarioEmail, assunto, corpoHtml);
            exigirCodigo(lerResposta(leitor), "250", "Envio do email falhou");

            // QUIT best-effort: apos 250 OK do DATA a entrega ja foi aceita pelo servidor
            try {
                escreverLinhaSmtp(saida, "QUIT");
                lerResposta(leitor);
            } catch (Exception ignored) { }
        } finally {
            if (socket != null && !socket.isClosed()) {
                try {
                    socket.close();
                } catch (Exception ignored) { }
            }
        }
    }

    private static Socket abrirConexao(SmtpCliente.SmtpConfig config) throws IOException {
        Socket rawSocket = new Socket();
        int connectTimeout = Math.min(config.timeoutMs, 3000);
        rawSocket.connect(new InetSocketAddress(config.host, config.porta), connectTimeout);
        rawSocket.setSoTimeout(config.timeoutMs);
        if (config.usarSsl) {
            SSLSocketFactory sslFactory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            SSLSocket sslSocket = (SSLSocket) sslFactory.createSocket(rawSocket, config.host, config.porta, true);
            sslSocket.startHandshake();
            sslSocket.setSoTimeout(config.timeoutMs);
            return sslSocket;
        }
        return rawSocket;
    }

    private static void autenticarSmtp(
            BufferedReader leitor,
            OutputStream saida,
            String respostaEhlo,
            String usuario,
            String senha) throws Exception {
        String upper = respostaEhlo != null ? respostaEhlo.toUpperCase(Locale.ROOT) : "";
        if (upper.contains("AUTH") && upper.contains("LOGIN")) {
            escreverLinhaSmtp(saida, "AUTH LOGIN");
            exigirCodigo(lerResposta(leitor), "334", "AUTH LOGIN rejeitado");
            escreverLinhaSmtp(saida, base64(usuario));
            exigirCodigo(lerResposta(leitor), "334", "Autenticacao SMTP interrompida");
            escreverLinhaSmtp(saida, base64(senha));
            exigirCodigo(lerResposta(leitor), "235", "Autenticacao SMTP falhou");
            return;
        }
        if (upper.contains("AUTH") && upper.contains("PLAIN")) {
            escreverLinhaSmtp(saida, "AUTH PLAIN " + base64("\0" + usuario + "\0" + senha));
            exigirCodigo(lerResposta(leitor), "235", "Autenticacao SMTP PLAIN falhou");
        }
    }

    private static void escreverCabecalhosECorpo(
            OutputStream saida,
            String remetente,
            String destinatario,
            String assunto,
            String corpoHtml) throws IOException {
        escreverLinhaSmtp(saida, "From: AGMRM <" + remetente + ">");
        escreverLinhaSmtp(saida, "To: " + destinatario);
        escreverLinhaSmtp(saida, "Subject: " + codificarSubjectRFC2047(assunto));
        escreverLinhaSmtp(saida, "MIME-Version: 1.0");
        escreverLinhaSmtp(saida, "Content-Type: text/html; charset=UTF-8");
        escreverLinhaSmtp(saida, "Content-Transfer-Encoding: 8bit");
        escreverLinhaSmtp(saida, "X-Mailer: AGMRM-Java-Native-SMTP");
        escreverLinhaSmtp(saida, "");
        escreverLinhaSmtp(saida, normalizarCorpoDataRfc5321(corpoHtml));
        escreverLinhaSmtp(saida, ".");
    }

    public static String normalizarCorpoDataRfc5321(String corpo) {
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

    private static String codificarSubjectRFC2047(String texto) {
        if (texto == null || texto.isEmpty()) return "";
        for (int i = 0; i < texto.length(); i++) {
            if (texto.charAt(i) > 127) {
                return "=?UTF-8?B?" + base64(texto) + "?=";
            }
        }
        return texto;
    }

    private static void exigirCodigo(String resposta, String prefixo, String mensagemErro) throws Exception {
        if (!resposta.startsWith(prefixo)) {
            throw new Exception(mensagemErro + ": " + resposta);
        }
    }

    private static void escreverLinhaSmtp(OutputStream saida, String linha) throws IOException {
        saida.write((linha + "\r\n").getBytes(StandardCharsets.UTF_8));
        saida.flush();
    }

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
            if (linha.length() >= 4 && linha.charAt(3) == ' ') {
                break;
            }
            builder.append("\n");
        }
        return builder.toString();
    }

    private static String base64(String texto) {
        return Base64.getEncoder().encodeToString(texto.getBytes(StandardCharsets.UTF_8));
    }
}
