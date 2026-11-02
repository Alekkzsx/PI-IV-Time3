// Desenvolvido por Marcelo Zarpelon

package videocall.hub;

import database.Colecao;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

// Guarda no banco as mensagens de chat que passam pelo hub; os demais envelopes sao ignorados.
public class RegistradorChat implements RegistradorEnvelope {
    private static final int LIMITE_TEXTO = 2000;

    private final Colecao mensagens;

    public RegistradorChat(Colecao mensagens) { this.mensagens = mensagens; }

    @Override
    public void registrar(String sala, Map<String, Object> envelope) {
        if (!"chat".equals(envelope.get("type"))) return;
        Object payload = envelope.get("payload");
        if (!(payload instanceof Map)) return;
        Map<?, ?> dados = (Map<?, ?>) payload;
        Object texto = dados.get("text") != null ? dados.get("text") : dados.get("content");
        if (!(texto instanceof String) || ((String) texto).isBlank()) return;
        String conteudo = (String) texto;
        if (conteudo.length() > LIMITE_TEXTO) conteudo = conteudo.substring(0, LIMITE_TEXTO);

        Object nome = envelope.get("senderName");
        Object quando = envelope.get("timestamp");
        Map<String, Object> documento = new LinkedHashMap<>();
        documento.put("id", UUID.randomUUID().toString());
        documento.put("salaId", sala);
        documento.put("remetenteId", envelope.get("senderId"));
        documento.put("remetente", nome instanceof String ? nome : "");
        documento.put("texto", conteudo);
        documento.put("enviadaEm", quando instanceof Long ? quando : (Object) System.currentTimeMillis());
        try {
            mensagens.inserir(documento);
        } catch (RuntimeException e) {
            // Falha ao gravar o historico nao pode derrubar a conversa em tempo real.
            System.err.println("[CHAT] Nao foi possivel gravar a mensagem: " + e.getMessage());
        }
    }
}
