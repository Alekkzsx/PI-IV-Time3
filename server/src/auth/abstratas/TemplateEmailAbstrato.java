// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

/**
 * Classe abstrata de templates HTML institucionais (Padrao Template Method).
 *
 * Centraliza a estrutura visual comum dos e-mails da plataforma AGMRM
 * (card centralizado, saudacao personalizada, rodape institucional e escape XSS),
 * delegando as subclasses apenas a cor de destaque, o titulo e o bloco de conteudo.
 */
public abstract class TemplateEmailAbstrato {
    private final String nomeDestinatario;

    /** @param nomeDestinatario nome para a saudacao personalizada (vazio = saudacao generica). */
    protected TemplateEmailAbstrato(String nomeDestinatario) {
        this.nomeDestinatario = nomeDestinatario;
    }

    /** Gancho visual: cor do titulo (identidade de cada tipo de e-mail). */
    protected abstract String getCorDestaque();

    /** Gancho: titulo do card (ex.: "Codigo de verificacao"). */
    protected abstract String getTitulo();

    /** Gancho: bloco HTML interno; dados do usuario DEVEM passar por escaparHtml antes. */
    protected abstract String getConteudoHtml();

    /**
     * Renderiza o documento HTML completo preservando o layout institucional.
     * final: o layout (card, saudacao, rodape) e unico; subclasses so variam os ganchos.
     * O nome do destinatario e escapado aqui para impedir XSS via nome cadastrado.
     */
    public final String renderizar() {
        String saudacao = (nomeDestinatario != null && !nomeDestinatario.trim().isEmpty())
                ? ", " + escaparHtml(nomeDestinatario.trim())
                : "";
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>"
                + "<body style=\"font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;\">"
                + "<div style=\"max-width: 500px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">"
                + "<h2 style=\"color: " + getCorDestaque() + "; margin-top: 0;\">" + getTitulo() + "</h2>"
                + "<p>Olá" + saudacao + "!</p>"
                + getConteudoHtml()
                + "<hr style=\"border: none; border-top: 1px solid #eee;\">"
                + "<p style=\"color: #999; font-size: 12px;\">AGMRM - Plataforma Educacional Integrada</p>"
                + "</div></body></html>";
    }

    /**
     * Escape HTML minimo anti-XSS: & primeiro (para nao re-escapar as entidades geradas),
     * depois < > " ' — cobre texto e valores de atributo.
     */
    public static String escaparHtml(String texto) {
        if (texto == null) {
            return "";
        }
        return texto.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
