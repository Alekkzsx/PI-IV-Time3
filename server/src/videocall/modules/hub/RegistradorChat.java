// Desenvolvido por Marcelo Zarpelon - RA: 25015323
// Adaptado para Java SE puro (Java 8+)
package videocall.modules.hub;

import videocall.modules.legado.VideoCallService;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Registra em memoria e sincroniza com o VideoCallService as mensagens de chat e eventos
 * de presenca que trafegam pelo hub WebSocket da videochamada.
 */
public class RegistradorChat implements RegistradorEnvelope {
    // Mensagem de chat truncada em 2000 chars (anti-abuso de payload).
    private static final int LIMITE_TEXTO = 2000;
    // Anel de 2000 mensagens em memoria: historico recente sem crescer indefinidamente.
    private static final int LIMITE_HISTORICO_MEMORIA = 2000;

    private final VideoCallService servico;
    // Guardado pelo proprio monitor da lista (synchronized(mensagensGravadas)).
    private final List<Map<String, Object>> mensagensGravadas = new ArrayList<Map<String, Object>>();

    /** Sem service: so o historico proprio (testes do registrador isolado). */
    public RegistradorChat() {
        this(null);
    }

    public RegistradorChat(VideoCallService servico) {
        this.servico = servico;
    }

    /** Despacho por tipo: chat vira historico; join/leave/hand_raise sincronizam o service legado. */
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

    /**
     * Persiste a mensagem de chat: aceita text ou content (aliases do cliente),
     * trunca no limite, entra no anel em memoria e espelha no VideoCallService
     * (best-effort: falha do espelho nao perde a mensagem do anel).
     */
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
            // Anel cheio: descarta a mais antiga antes de acrescentar a nova.
            if (mensagensGravadas.size() >= LIMITE_HISTORICO_MEMORIA) {
                mensagensGravadas.remove(0);
            }
            mensagensGravadas.add(documento);
        }

        if (servico != null && !remetenteId.isEmpty()) {
            try {
                servico.obterOuCriarSala(sala);
                servico.adicionarMensagemChat(sala, remetenteId, nome.isEmpty() ? remetenteId : nome, papel, conteudo);
            } catch (RuntimeException e) {
                System.err.println("[CHAT] Nao foi possivel gravar a mensagem: " + e.getMessage());
            }
        }
    }

    /**
     * Espelha a telemetria do WS no estado legado: join entra na sala (abrindo-a se
     * preciso - o ticket do upgrade ja autorizou a sessao), leave sai, hand_raise
     * alterna a fila FIFO. Falhas do service sao engolidas: o hub nao pode cair por isso.
     */
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
                    if (roleObj instanceof String && !((String) roleObj).trim().isEmpty()) papel = (String) roleObj;
                    Object nameObj = ((Map<?, ?>) payload).get("name");
                    if (nameObj instanceof String && !((String) nameObj).trim().isEmpty()) nome = (String) nameObj;
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
        } catch (RuntimeException ignored) { }
    }

    /** Historico de chat (opcionalmente filtrado por sala) em copias imutaveis. */
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
