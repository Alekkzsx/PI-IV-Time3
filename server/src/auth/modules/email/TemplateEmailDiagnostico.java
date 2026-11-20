// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.TemplateEmailAbstrato;

import java.time.LocalDateTime;

/**
 * Template HTML para testes administrativos de diagnostico de entrega de e-mail.
 */
public class TemplateEmailDiagnostico extends TemplateEmailAbstrato {
    private final String destinatario;

    public TemplateEmailDiagnostico(String nomeAdmin, String destinatario) {
        super(nomeAdmin);
        this.destinatario = destinatario;
    }

    @Override
    protected String getCorDestaque() {
        return "#0d47a1";
    }

    @Override
    protected String getTitulo() {
        return "&#128231; Diagnóstico de Email AGMRM";
    }

    @Override
    protected String getConteudoHtml() {
        String timestamp = LocalDateTime.now().toString();
        return "<p>Este é um email de teste enviado pelo sistema de diagnóstico.</p>"
                + "<div style=\"background: #e3f2fd; border-radius: 8px; padding: 20px; margin: 20px 0;\">"
                + "<p style=\"margin: 5px 0;\"><strong>Destinatário:</strong> " + escaparHtml(destinatario) + "</p>"
                + "<p style=\"margin: 5px 0;\"><strong>Timestamp:</strong> " + escaparHtml(timestamp) + "</p>"
                + "<p style=\"margin: 5px 0;\"><strong>Status:</strong> <span style=\"color: green;\">✓ Sucesso</span></p>"
                + "</div>"
                + "<p style=\"color: #666; font-size: 14px;\">Se você recebeu este email, o serviço SMTP está funcionando corretamente.</p>";
    }
}
