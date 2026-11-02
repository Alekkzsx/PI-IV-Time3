// Desenvolvido por Marcelo Zarpelon

package videocall.hub;

import utils.Json;
import websocket.ConexaoWebSocket;
import websocket.OuvinteWebSocket;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

// Repassa os envelopes p2p_videocall_v1 entre os participantes da mesma sala.
public class SalaVideoHub implements OuvinteWebSocket {
    public static final String PROTOCOLO = "p2p_videocall_v1";
    public static final int MAXIMO_PARTICIPANTES = 50;
    private static final Set<String> TIPOS = Set.of("join", "presence_sync", "heartbeat", "leave", "chat",
            "emoji", "hand_raise", "media_state", "recording_state", "webrtc_signal");

    private final Map<String, List<ConexaoWebSocket>> salas = new HashMap<>();
    private final Map<ConexaoWebSocket, String> remetentes = new HashMap<>();
    private final RegistradorEnvelope registrador;

    public SalaVideoHub(RegistradorEnvelope registrador) { this.registrador = registrador; }

    @Override
    public void aoAbrir(ConexaoWebSocket conexao) {
        boolean lotada;
        synchronized (this) {
            List<ConexaoWebSocket> sala = salas.computeIfAbsent(conexao.getRecurso(), k -> new ArrayList<>());
            lotada = sala.size() >= MAXIMO_PARTICIPANTES;
            if (!lotada) sala.add(conexao);
        }
        if (lotada) conexao.fechar(1013);
    }

    @Override
    public void aoReceberTexto(ConexaoWebSocket conexao, String texto) {
        Map<String, Object> envelope;
        try {
            envelope = Json.analisarObjeto(texto);
        } catch (IllegalArgumentException e) {
            conexao.fechar(1007);
            return;
        }
        String sala = conexao.getRecurso();
        Object tipo = envelope.get("type");
        Object remetente = envelope.get("senderId");
        boolean valido = PROTOCOLO.equals(envelope.get("protocol"))
                && sala.equals(envelope.get("roomId"))
                && tipo instanceof String && TIPOS.contains(tipo)
                && remetente instanceof String && !((String) remetente).isBlank() && ((String) remetente).length() <= 80;
        if (!valido) { conexao.fechar(1008); return; }

        synchronized (this) {
            // O primeiro remetente fica preso a conexao, impedindo que um cliente se passe por outro.
            String conhecido = remetentes.putIfAbsent(conexao, (String) remetente);
            if (conhecido != null && !conhecido.equals(remetente)) { conexao.fechar(1008); return; }
        }
        if (registrador != null) registrador.registrar(sala, envelope);
        repassar(sala, conexao, texto);
    }

    @Override
    public void aoFechar(ConexaoWebSocket conexao) {
        String sala = conexao.getRecurso();
        String remetente;
        synchronized (this) {
            List<ConexaoWebSocket> participantes = salas.get(sala);
            if (participantes != null) {
                participantes.remove(conexao);
                if (participantes.isEmpty()) salas.remove(sala);
            }
            remetente = remetentes.remove(conexao);
        }
        if (remetente == null) return;
        // Avisa os demais para que a presenca seja limpa sem esperar o watchdog.
        Map<String, Object> saida = new LinkedHashMap<>();
        saida.put("protocol", PROTOCOLO);
        saida.put("type", "leave");
        saida.put("roomId", sala);
        saida.put("senderId", remetente);
        saida.put("timestamp", System.currentTimeMillis());
        saida.put("payload", new LinkedHashMap<String, Object>());
        if (registrador != null) registrador.registrar(sala, saida);
        repassar(sala, conexao, Json.escrever(saida));
    }

    public synchronized int contarParticipantes(String sala) {
        List<ConexaoWebSocket> participantes = salas.get(sala);
        return participantes == null ? 0 : participantes.size();
    }

    private void repassar(String sala, ConexaoWebSocket origem, String texto) {
        List<ConexaoWebSocket> destinos;
        synchronized (this) {
            List<ConexaoWebSocket> participantes = salas.get(sala);
            if (participantes == null) return;
            destinos = new ArrayList<>(participantes);
        }
        for (ConexaoWebSocket destino : destinos) {
            if (destino == origem) continue;
            try { destino.enviarTexto(texto); }
            catch (IOException e) { destino.fechar(1011); }
        }
    }
}
