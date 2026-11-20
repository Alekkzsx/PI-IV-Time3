// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.modules.hub;

import utils.Json;
import websocket.ConexaoWebSocket;
import websocket.OuvinteWebSocket;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Repassa envelopes p2p_videocall_v1 entre participantes conectados na mesma sala WebSocket.
 *
 * Isolamento por sala: um envelope so alcanca conexoes do MESMO roomId (e o roomId
 * precisa bater com a sala autorizada no ticket do upgrade - nao da para "pular" de sala).
 * Validacao de protocolo: JSON + protocol/roomId/type/senderId conferidos; senderId fica
 * FIXADO na primeira mensagem da conexao (impede personificar outro participante).
 * Threading: estado protegido por synchronized(this); envios acontecem fora do lock.
 */
public class SalaVideoHub implements OuvinteWebSocket {
    // Identificador do protocolo de envelope compartilhado com o frontend Flutter.
    public static final String PROTOCOLO = "p2p_videocall_v1";
    // Teto de participantes por sala: malha P2P de midia nao escala alem disso.
    public static final int MAXIMO_PARTICIPANTES = 50;
    // Whitelist de tipos de envelope: qualquer outro tipo derruba a conexao (1008).
    private static final Set<String> TIPOS = Collections.unmodifiableSet(new HashSet<String>(Arrays.asList(
            "join", "presence_sync", "heartbeat", "leave", "chat", "emoji",
            "hand_raise", "media_state", "recording_state", "webrtc_signal")));

    // sala -> conexoes; conexao -> senderId fixado. Ambos sob o lock do hub.
    private final Map<String, List<ConexaoWebSocket>> salas = new HashMap<String, List<ConexaoWebSocket>>();
    private final Map<ConexaoWebSocket, String> remetentes = new HashMap<ConexaoWebSocket, String>();
    private final RegistradorEnvelope registrador;

    /** @param registrador observador de envelopes (chat/telemetria); null desliga o registro. */
    public SalaVideoHub(RegistradorEnvelope registrador) {
        this.registrador = registrador;
    }

    /** Registra a conexao na sala; sala lotada fecha com 1013 (Try Again Later) fora do lock. */
    @Override
    public void aoAbrir(ConexaoWebSocket conexao) {
        boolean lotada;
        synchronized (this) {
            List<ConexaoWebSocket> sala = salas.get(conexao.getRecurso());
            if (sala == null) {
                sala = new ArrayList<ConexaoWebSocket>();
                salas.put(conexao.getRecurso(), sala);
            }
            lotada = sala.size() >= MAXIMO_PARTICIPANTES;
            if (!lotada) sala.add(conexao);
        }
        if (lotada) conexao.fechar(1013);
    }

    /**
     * Valida e roteia um envelope: JSON invalido -> 1007; violacao de protocolo
     * (protocol/roomId/tipo/senderId) -> 1008; senderId diferente do fixado -> 1008.
     * Valido: registra (chat/presenca) e repassa aos demais da sala.
     */
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
                && remetente instanceof String && !((String) remetente).trim().isEmpty()
                && ((String) remetente).length() <= 80;
        if (!valido) { conexao.fechar(1008); return; }

        synchronized (this) {
            // Primeira mensagem fixa o senderId da conexao; trocar depois = tentativa de personificacao.
            String conhecido = remetentes.get(conexao);
            if (conhecido == null) remetentes.put(conexao, (String) remetente);
            else if (!conhecido.equals(remetente)) { conexao.fechar(1008); return; }
        }
        if (registrador != null) registrador.registrar(sala, envelope);
        repassar(sala, conexao, texto);
    }

    /**
     * Conexao caiu: remove da sala e SINTETIZA um envelope leave em nome do remetente,
     * para os peers limparem o participante mesmo sem mensagem de despedida do cliente.
     */
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
        Map<String, Object> saida = new LinkedHashMap<String, Object>();
        saida.put("protocol", PROTOCOLO);
        saida.put("type", "leave");
        saida.put("roomId", sala);
        saida.put("senderId", remetente);
        saida.put("timestamp", Long.valueOf(System.currentTimeMillis()));
        saida.put("payload", new LinkedHashMap<String, Object>());
        if (registrador != null) registrador.registrar(sala, saida);
        repassar(sala, conexao, Json.escrever(saida));
    }

    /** @return total de conexoes vivas na sala (diagnostico/testes). */
    public synchronized int contarParticipantes(String sala) {
        List<ConexaoWebSocket> participantes = salas.get(sala);
        return participantes == null ? 0 : participantes.size();
    }

    /**
     * Fan-out para a sala MENOS a origem. Snapshot da lista sob lock; envio fora do lock
     * (enviarTexto pode bloquear em I/O e nao deve travar o hub inteiro).
     * Falha de envio fecha o destino com 1011 (erro interno) e segue para os demais.
     */
    private void repassar(String sala, ConexaoWebSocket origem, String texto) {
        List<ConexaoWebSocket> destinos;
        synchronized (this) {
            List<ConexaoWebSocket> participantes = salas.get(sala);
            if (participantes == null) return;
            destinos = new ArrayList<ConexaoWebSocket>(participantes);
        }
        for (ConexaoWebSocket destino : destinos) {
            if (destino == origem) continue;
            try { destino.enviarTexto(texto); }
            catch (IOException e) { destino.fechar(1011); }
        }
    }
}
