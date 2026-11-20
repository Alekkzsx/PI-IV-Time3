// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.TemplateEmailAbstrato;

/**
 * Template HTML de boas-vindas com credenciais iniciais da conta institucional.
 */
public class TemplateEmailBoasVindas extends TemplateEmailAbstrato {
    private final String identidade;
    private final String perfil;
    private final String senhaTemporaria;

    public TemplateEmailBoasVindas(String nomeDestinatario, String identidade, String perfil, String senhaTemporaria) {
        super(nomeDestinatario);
        this.identidade = identidade;
        this.perfil = perfil;
        this.senhaTemporaria = senhaTemporaria;
    }

    @Override
    protected String getCorDestaque() {
        return "#0f172a";
    }

    @Override
    protected String getTitulo() {
        return "Bem-vindo ao Portal AGMRM";
    }

    @Override
    protected String getConteudoHtml() {
        String blocoSenha = (senhaTemporaria != null && !senhaTemporaria.isEmpty())
                ? "<p><strong>Senha temporária:</strong> <code>" + escaparHtml(senhaTemporaria) + "</code></p>"
                : "";
        return "<p>Sua conta institucional (" + escaparHtml(perfil != null ? perfil : "") + ") foi criada.</p>"
                + "<p><strong>Identidade:</strong> " + escaparHtml(identidade != null ? identidade : "") + "</p>"
                + blocoSenha;
    }
}
