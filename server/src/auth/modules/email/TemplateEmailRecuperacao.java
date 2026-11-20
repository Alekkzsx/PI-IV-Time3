// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.TemplateEmailAbstrato;

/**
 * Template HTML para codigo OTP de recuperacao de senha.
 */
public class TemplateEmailRecuperacao extends TemplateEmailAbstrato {
    private final String codigo;

    public TemplateEmailRecuperacao(String nomeDestinatario, String codigo) {
        super(nomeDestinatario);
        this.codigo = codigo;
    }

    @Override
    protected String getCorDestaque() {
        return "#e65100";
    }

    @Override
    protected String getTitulo() {
        return "&#128273; Recuperação de Senha";
    }

    @Override
    protected String getConteudoHtml() {
        return "<p>Recebemos uma solicitação para redefinir sua senha. Use o código abaixo:</p>"
                + "<div style=\"background: #fff3e0; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;\">"
                + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #e65100;\">"
                + escaparHtml(codigo) + "</span></div>"
                + "<p style=\"color: #666; font-size: 14px;\">Este código expira em 5 minutos.</p>"
                + "<p style=\"color: #999; font-size: 12px;\">Se você não solicitou, ignore este email com segurança.</p>";
    }
}
