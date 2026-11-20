// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalEnvioEmailAbstrato;
import auth.modules.persistencia.RepositorioUsuarios;
import org.bson.Document;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Canal Tier 3: Outbox local de seguranca (zero crash).
 * Retem historico circular em memoria (50 itens), exibe moldura diagnostica no console
 * e persiste na colecao MongoDB email_outbox quando disponivel.
 */
public class CanalOutboxLocal extends CanalEnvioEmailAbstrato {
    private static final int LIMITE_HISTORICO = 50;
    private static final Queue<SmtpCliente.EmailOutboxItem> HISTORICO =
            new ConcurrentLinkedQueue<SmtpCliente.EmailOutboxItem>();

    @Override
    public String getNomeCanal() {
        return "OUTBOX";
    }

    @Override
    public boolean estaConfigurado() {
        return true;
    }

    public static void registrarNoHistorico(MensagemEmail mensagem, String canal) {
        HISTORICO.offer(new SmtpCliente.EmailOutboxItem(
                mensagem.getDestinatario(),
                mensagem.getAssunto(),
                mensagem.getCodigoOtp(),
                mensagem.getTipo(),
                canal
        ));
        while (HISTORICO.size() > LIMITE_HISTORICO) {
            HISTORICO.poll();
        }
    }

    public static List<SmtpCliente.EmailOutboxItem> getHistorico() {
        return new ArrayList<SmtpCliente.EmailOutboxItem>(HISTORICO);
    }

    @Override
    protected boolean enviarInterno(MensagemEmail mensagem, List<String> errorTrail) {
        String codigoOtp = mensagem.getCodigoOtp();
        registrarNoHistorico(mensagem, "OUTBOX");

        String destinatarioFormatado = truncar(mensagem.getDestinatario(), 56);
        String assuntoFormatado = truncar(mensagem.getAssunto(), 56);
        String otpFormatado = codigoOtp != null ? codigoOtp : "------";

        StringBuilder moldura = new StringBuilder();
        moldura.append("\n")
                .append("┌════════════════════════════════════════════════════════════════════┐\n")
                .append("│ 📬 [OUTBOX LOCAL / RESILIÊNCIA ATIVA]                               │\n")
                .append(String.format("│ Para:    %-58s │\n", destinatarioFormatado))
                .append(String.format("│ Assunto: %-58s │\n", assuntoFormatado))
                .append("│                                                                    │\n")
                .append(String.format("│   CÓDIGO DE VERIFICAÇÃO OTP:  [ %-6s ]                           │\n", otpFormatado))
                .append("│                                                                    │\n");
        if (errorTrail != null && !errorTrail.isEmpty()) {
            moldura.append("│ Motivos do failover:                                               │\n");
            for (String err : errorTrail) {
                moldura.append(String.format("│ • %-64s │\n", truncar(err, 64)));
            }
        }
        moldura.append("└════════════════════════════════════════════════════════════════════┘\n");

        System.out.println(moldura.toString());
        persistirOutboxMongo(mensagem, codigoOtp, errorTrail);
        log("INFO", "[OUTBOX REGISTRADO] Email retido em outbox local para "
                + mensagem.getDestinatario() + " | OTP=" + otpFormatado);
        return true;
    }

    private static void persistirOutboxMongo(MensagemEmail mensagem, String codigoOtp, List<String> errorTrail) {
        try {
            RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
            if (repo == null || repo.getEmailOutboxCollection() == null) {
                return;
            }
            Date agora = new Date();
            Date expira = new Date(System.currentTimeMillis() + 86_400_000L);
            Document doc = new Document()
                    .append("id", "java_outbox_" + System.currentTimeMillis())
                    .append("to", mensagem.getDestinatario())
                    .append("subject", mensagem.getAssunto())
                    .append("html", mensagem.getCorpoHtml())
                    .append("text", mensagem.getAssunto() + (codigoOtp != null ? " | Codigo: " + codigoOtp : ""))
                    .append("provider", "outbox")
                    .append("purpose", mensagem.getTipo())
                    .append("createdAt", agora)
                    .append("expiresAt", expira);
            if (codigoOtp != null) {
                doc.append("code", codigoOtp);
            }
            if (errorTrail != null && !errorTrail.isEmpty()) {
                doc.append("errorTrail", errorTrail);
            }
            repo.getEmailOutboxCollection().insertOne(doc);
        } catch (Exception ignored) { }
    }
}
