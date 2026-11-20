// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.TemplateEmailAbstrato;

/**
 * Template HTML para envio de codigo de verificacao 2FA (OTP).
 */
public class TemplateEmailOtp extends TemplateEmailAbstrato {
    private final String codigo;

    /** @param codigo OTP de 6 digitos gerado pelo OtpService. */
    public TemplateEmailOtp(String nomeDestinatario, String codigo) {
        super(nomeDestinatario);
        this.codigo = codigo;
    }

    @Override
    protected String getCorDestaque() {
        return "#1a73e8";
    }

    @Override
    protected String getTitulo() {
        return "&#128274; Verificação de Segurança";
    }

    /** Caixa de destaque com o codigo grande e espacado (facilita leitura/digitacao) + aviso de validade. */
    @Override
    protected String getConteudoHtml() {
        return "<p>Use o código abaixo para verificar sua identidade:</p>"
                + "<div style=\"background: #e8f0fe; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;\">"
                + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a73e8;\">"
                + escaparHtml(codigo) + "</span></div>"
                + "<p style=\"color: #666; font-size: 14px;\">Este código expira em 5 minutos. Não compartilhe com ninguém.</p>";
    }
}
