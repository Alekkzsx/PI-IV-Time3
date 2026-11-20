// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * DTO imutavel que representa uma mensagem de e-mail transacional e seus utilitarios de parsing.
 */
public final class MensagemEmail {
    // OTP = sequencia de 6 digitos isolada (lookarounds impedem casar pedaco de numero maior).
    private static final Pattern OTP_PATTERN = Pattern.compile("(?<!\\d)(\\d{6})(?!\\d)");
    // Endereco no formato RFC "Nome de Exibicao <email@dominio>": captura o conteudo dos angulos.
    private static final Pattern EMAIL_ANGULO_PATTERN = Pattern.compile("<([^>]+)>");

    private final String destinatario;
    private final String assunto;
    private final String corpoHtml;
    private final String tipo;

    /** Construtor null-safe: campos ausentes viram "" (tipo vira GENERIC). */
    public MensagemEmail(String destinatario, String assunto, String corpoHtml, String tipo) {
        this.destinatario = destinatario != null ? destinatario.trim() : "";
        this.assunto = assunto != null ? assunto : "";
        this.corpoHtml = corpoHtml != null ? corpoHtml : "";
        this.tipo = tipo != null ? tipo : "GENERIC";
    }

    /** @return endereco do destinatario (trim). */
    public String getDestinatario() { return destinatario; }
    /** @return assunto do e-mail. */
    public String getAssunto() { return assunto; }
    /** @return corpo HTML renderizado pelo template. */
    public String getCorpoHtml() { return corpoHtml; }
    /** @return tipo transacional (OTP, RECOVERY, WELCOME, DIAGNOSTIC, GENERIC). */
    public String getTipo() { return tipo; }

    /** Versao texto-plano do corpo (alternativa text/plain exigida por bons clientes de e-mail). */
    public String getTextoPlano() {
        return extrairTextoPlano(corpoHtml, assunto);
    }

    /** OTP embutido no corpo (usado pelo outbox para exibir o codigo retido no console). */
    public String getCodigoOtp() {
        return extrairCodigoOtp(corpoHtml);
    }

    /** Primeiro grupo de 6 digitos isolados no HTML, ou null se nao houver. */
    public static String extrairCodigoOtp(String html) {
        if (html == null) {
            return null;
        }
        Matcher m = OTP_PATTERN.matcher(html);
        return m.find() ? m.group(1) : null;
    }

    /** Extrai o endereco puro de "Nome <email@x>"; sem angulos, devolve o proprio valor com trim. */
    public static String extrairEmailPuro(String valor) {
        if (valor == null) {
            return "";
        }
        String limpo = valor.trim();
        Matcher m = EMAIL_ANGULO_PATTERN.matcher(limpo);
        return m.find() ? m.group(1).trim() : limpo;
    }

    /**
     * Converte HTML em texto legivel: remove style/script inteiros, transforma <br> e
     * fechamentos de bloco em quebras de linha, remove as demais tags, decodifica as
     * entidades basicas e colapsa espacos. Corpo vazio resultante cai no assunto.
     */
    public static String extrairTextoPlano(String html, String fallbackAssunto) {
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
}
