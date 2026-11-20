// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

import auth.modules.email.MensagemEmail;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Classe abstrata base para canais de envio de e-mail da arquitetura de resiliencia em 3 tiers
 * (Padrao Strategy / Chain of Responsibility + Template Method).
 *
 * Subclasses concretas:
 * - Tier 1: CanalSmtpNativo
 * - Tier 2: CanalResendEmail, CanalBrevoEmail, CanalWebhookEmail (via CanalHttpsEmailAbstrato)
 * - Tier 3: CanalOutboxLocal
 */
public abstract class CanalEnvioEmailAbstrato {
    private static final DateTimeFormatter LOG_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public abstract String getNomeCanal();

    public abstract boolean estaConfigurado();

    /**
     * Template Method que verifica configuracao, executa o disparo e protege a cadeia contra falhas.
     */
    public final boolean tentarEnviar(MensagemEmail mensagem, List<String> errorTrail) {
        if (!estaConfigurado()) {
            registrarNaoConfigurado(errorTrail);
            return false;
        }
        try {
            return enviarInterno(mensagem, errorTrail);
        } catch (Exception e) {
            String msg = getNomeCanal() + " falhou: " + e.getMessage();
            if (errorTrail != null) {
                errorTrail.add(msg);
            }
            log("WARN", "[FALHA CANAL " + getNomeCanal() + "] " + msg);
            return false;
        }
    }

    protected abstract boolean enviarInterno(MensagemEmail mensagem, List<String> errorTrail) throws Exception;

    protected void registrarNaoConfigurado(List<String> errorTrail) {
        // Opcional nas subclasses
    }

    public static void log(String nivel, String mensagem) {
        String timestamp = LocalDateTime.now().format(LOG_FORMAT);
        String linha = String.format("[%s] [SMTP] [%s] %s", timestamp, nivel, mensagem);
        if ("ERROR".equals(nivel)) {
            System.err.println(linha);
        } else {
            System.out.println(linha);
        }
    }

    protected static String truncar(String texto, int max) {
        if (texto == null) {
            return "";
        }
        if (texto.length() <= max) {
            return texto;
        }
        return texto.substring(0, max - 3) + "...";
    }
}
