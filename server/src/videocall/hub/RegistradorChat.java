// Desenvolvido por Marcelo Zarpelon e adaptado para Java SE puro (Java 8+)

package videocall.hub;

import videocall.VideoCallService;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Registra em memoria e sincroniza com o VideoCallService as mensagens de chat e eventos
 * de presenca que trafegam pelo hub WebSocket da videochamada, sem bibliotecas externas.
 */
public class RegistradorChat implements RegistradorEnvelope {
    private static final int LIMITE_TEXTO = 2000;
    private static final int LIMITE_HISTORICO_MEMORIA = 2000;

    private final VideoCallService servico;
    private final List<Map<String, Object>> mensagensGravadas = new ArrayList<Map<String, Object>>();

    public RegistradorChat() {
        this(null);
    }

    public RegistradorChat(VideoCallService servico) {
        this.servico = servico;
    }

    @Override
    public void registrar(String sala, Map<String, Object> envelope) {
        if (envelope == null) return;
        Object tipoObj = envelope.get("type");
        if (!(tipoObj instanceof String)) return;
        String tipo = (String) tipoObj;

        if ("chat".equals(tipo)) {
            registrarMensagemChat(sala, envelope);
        } else if (servico != null) {
            sincronizarTelemetriaSala(sala, tipo, envelope);
        }
    }

    private void registrarMensagemChat(String sala, Map<String, Object> envelope) {
        Object payload = envelope.get("payload");
        if (!(payload instanceof Map)) return;
        Map<?, ?> dados = (Map<?, ?>) payload;
        Object texto = dados.get("text") != null ? dados.get("text") : dados.get("content");
        if (!(texto instanceof String) || ((String) texto).trim().isEmpty()) return;

        String conteudo = (String) texto;
        if (conteudo.length() > LIMITE_TEXTO) {
            conteudo = conteudo.substring(0, LIMITE_TEXTO);
        }

        String remetenteId = envelope.get("senderId") instanceof String ? (String) envelope.get("senderId") : "";
        String nome = envelope.get("senderName") instanceof String ? (String) envelope.get("senderName") : "";
        String papel = dados.get("senderRole") instanceof String ? (String) dados.get("senderRole") : "aluno";
        Object quando = envelope.get("timestamp");
        long sentAt = quando instanceof Number ? ((Number) quando).longValue() : System.currentTimeMillis();

        Map<String, Object> documento = new LinkedHashMap<String, Object>();
        documento.put("id", UUID.randomUUID().toString());
        documento.put("roomId", sala);
        documento.put("senderId", remetenteId);
        documento.put("senderName", nome);
        documento.put("text", conteudo);
        documento.put("sentAt", Long.valueOf(sentAt));

        synchronized (mensagensGravadas) {
            if (mensagensGravadas.size() >= LIMITE_HISTORICO_MEMORIA) {
                mensagensGravadas.remove(0);
            }
            mensagensGravadas.add(documento);
        }

        if (servico != null && !remetenteId.isEmpty()) {
            try {
                servico.obterOuCriarSala(sala);
                servico.adicionarMensagemChat(
                        sala,
                        remetenteId,
                        nome.isEmpty() ? remetenteId : nome,
                        papel,
                        conteudo);
            } catch (RuntimeException e) {
                // Falha ao gravar o historico nao pode derrubar a conversa em tempo real.
                System.err.println("[CHAT] Nao foi possivel gravar a mensagem: " + e.getMessage());
            }
        }
    }

    private void sincronizarTelemetriaSala(String sala, String tipo, Map<String, Object> envelope) {
        String remetenteId = envelope.get("senderId") instanceof String ? (String) envelope.get("senderId") : "";
        if (remetenteId.isEmpty()) return;

        try {
            if ("join".equals(tipo)) {
                String nome = envelope.get("senderName") instanceof String ? (String) envelope.get("senderName") : remetenteId;
                String papel = "aluno";
                Object payload = envelope.get("payload");
                if (payload instanceof Map) {
                    Object roleObj = ((Map<?, ?>) payload).get("role");
                    if (roleObj instanceof String && !((String) roleObj).trim().isEmpty()) {
                        papel = (String) roleObj;
                    }
                    Object nameObj = ((Map<?, ?>) payload).get("name");
                    if (nameObj instanceof String && !((String) nameObj).trim().isEmpty()) {
                        nome = (String) nameObj;
                    }
                }
                VideoCallService.Room room = servico.obterOuCriarSala(sala);
                if (!room.isOpen) {
                    servico.abrirSala(sala, "docente", "Sessao WebSocket Autorizada");
                }
                servico.entrarNaSala(sala, remetenteId, nome, papel);
            } else if ("leave".equals(tipo)) {
                servico.sairDaSala(sala, remetenteId);
            } else if ("hand_raise".equals(tipo)) {
                Object payload = envelope.get("payload");
                if (payload instanceof Map) {
                    Object raised = ((Map<?, ?>) payload).get("raised");
                    if (raised instanceof Boolean) {
                        servico.alternarMaoLevantada(sala, remetenteId, ((Boolean) raised).booleanValue());
                    }
                }
            }
        } catch (RuntimeException ignored) {
            // Sincronizacao auxiliar nao deve interromper o fluxo WebSocket
        }
    }

    public List<Map<String, Object>> listarMensagens(String filtroSala) {
        synchronized (mensagensGravadas) {
            List<Map<String, Object>> copia = new ArrayList<Map<String, Object>>();
            for (int i = 0; i < mensagensGravadas.size(); i++) {
                Map<String, Object> msg = mensagensGravadas.get(i);
                if (filtroSala == null || filtroSala.equals(msg.get("roomId"))) {
                    copia.add(Collections.unmodifiableMap(new LinkedHashMap<String, Object>(msg)));
                }
            }
            return copia;
        }
    }
}
