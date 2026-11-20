// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * DTO imutavel que representa uma mensagem de e-mail transacional e seus utilitarios de parsing.
 */
public final class MensagemEmail {
    private static final Pattern OTP_PATTERN = Pattern.compile("(?<!\\d)(\\d{6})(?!\\d)");
    private static final Pattern EMAIL_ANGULO_PATTERN = Pattern.compile("<([^>]+)>");

    private final String destinatario;
    private final String assunto;
    private final String corpoHtml;
    private final String tipo;

    public MensagemEmail(String destinatario, String assunto, String corpoHtml, String tipo) {
        this.destinatario = destinatario != null ? destinatario.trim() : "";
        this.assunto = assunto != null ? assunto : "";
        this.corpoHtml = corpoHtml != null ? corpoHtml : "";
        this.tipo = tipo != null ? tipo : "GENERIC";
    }

    public String getDestinatario() { return destinatario; }
    public String getAssunto() { return assunto; }
    public String getCorpoHtml() { return corpoHtml; }
    public String getTipo() { return tipo; }

    public String getTextoPlano() {
        return extrairTextoPlano(corpoHtml, assunto);
    }

    public String getCodigoOtp() {
        return extrairCodigoOtp(corpoHtml);
    }

    public static String extrairCodigoOtp(String html) {
        if (html == null) {
            return null;
        }
        Matcher m = OTP_PATTERN.matcher(html);
        return m.find() ? m.group(1) : null;
    }

    public static String extrairEmailPuro(String valor) {
        if (valor == null) {
            return "";
        }
        String limpo = valor.trim();
        Matcher m = EMAIL_ANGULO_PATTERN.matcher(limpo);
        return m.find() ? m.group(1).trim() : limpo;
    }

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
