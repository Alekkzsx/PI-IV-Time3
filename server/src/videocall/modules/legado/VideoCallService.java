// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall.modules.legado;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Servico em memoria para gestao de salas, sinalizacao, presenca e interacao da videochamada.
 */
public class VideoCallService {
    private static final VideoCallService INSTANCIA = new VideoCallService();

    public static VideoCallService getInstance() {
        return INSTANCIA;
    }

    public static class Participant {
        public final String ra;
        public final String name;
        public final String role;
        public final long joinedAt;
        public long leftAt = 0;
        public boolean isHandRaised = false;
        public long handRaisedAt = 0;

        public Participant(String ra, String name, String role) {
            this.ra = ra;
            this.name = name;
            this.role = role != null ? role.toLowerCase(Locale.ROOT) : "aluno";
            this.joinedAt = System.currentTimeMillis();
        }

        public long getConnectedMinutes() {
            long end = leftAt > 0 ? leftAt : System.currentTimeMillis();
            return Math.max(1, (end - joinedAt) / 60000);
        }
    }

    public static class SignalingMessage {
        public final String id;
        public final String fromRa;
        public final String toRa;
        public final String type;
        public final String data;
        public final long timestamp;

        public SignalingMessage(String fromRa, String toRa, String type, String data) {
            this.id = UUID.randomUUID().toString();
            this.fromRa = fromRa;
            this.toRa = toRa;
            this.type = type;
            this.data = data;
            this.timestamp = System.currentTimeMillis();
        }
    }

    public static class ChatMessage {
        public final String id;
        public final String senderRa;
        public final String senderName;
        public final String senderRole;
        public final String message;
        public final String timeFormatted;

        public ChatMessage(String senderRa, String senderName, String senderRole, String message) {
            this.id = UUID.randomUUID().toString();
            this.senderRa = senderRa;
            this.senderName = senderName;
            this.senderRole = senderRole;
            this.message = message;
            this.timeFormatted = new SimpleDateFormat("HH:mm:ss").format(new Date());
        }
    }

    public static class Room {
        public final String roomCode;
        public boolean isOpen = false;
        public String openedByRole = null;
        public String openedByName = null;
        public long openedAt = 0;
        public long closedAt = 0;

        public final Map<String, Participant> activeParticipants = new ConcurrentHashMap<String, Participant>();
        public final List<Participant> attendanceHistory = new ArrayList<Participant>();
        public final List<ChatMessage> chatHistory = new ArrayList<ChatMessage>();
        public final List<String> handRaiseQueue = new ArrayList<String>();
        public final Map<String, Queue<SignalingMessage>> peerSignalQueues =
                new ConcurrentHashMap<String, Queue<SignalingMessage>>();

        public Room(String roomCode) {
            this.roomCode = roomCode;
        }

        public int getTotalDurationMinutes() {
            if (openedAt == 0) return 0;
            long end = closedAt > 0 ? closedAt : System.currentTimeMillis();
            return (int) Math.max(1, (end - openedAt) / 60000);
        }
    }

    private final Map<String, Room> rooms = new ConcurrentHashMap<String, Room>();

    private VideoCallService() {
        obterOuCriarSala("APS-II");
        obterOuCriarSala("BD-II");
        obterOuCriarSala("FSO");
    }

    public synchronized Room obterOuCriarSala(String roomCode) {
        String code = roomCode != null ? roomCode.trim().toUpperCase(Locale.ROOT) : "GERAL";
        Room r = rooms.get(code);
        if (r == null) {
            r = new Room(code);
            rooms.put(code, r);
        }
        return r;
    }

    public Map<String, Room> listarSalas() {
        return Collections.unmodifiableMap(rooms);
    }

    public synchronized boolean abrirSala(String roomCode, String role, String name) {
        String normalizedRole = role != null ? role.trim().toLowerCase(Locale.ROOT) : "";
        if (!"docente".equals(normalizedRole) && !"teacher".equals(normalizedRole)
                && !"admin".equals(normalizedRole) && !"moderator".equals(normalizedRole)) {
            return false;
        }
        Room r = obterOuCriarSala(roomCode);
        r.isOpen = true;
        r.openedByRole = normalizedRole;
        r.openedByName = name != null ? name : "Docente Responsavel";
        r.openedAt = System.currentTimeMillis();
        r.closedAt = 0;
        return true;
    }

    public synchronized boolean fecharSala(String roomCode, String role) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null || !r.isOpen) return false;
        r.isOpen = false;
        r.closedAt = System.currentTimeMillis();
        for (Participant p : r.activeParticipants.values()) {
            p.leftAt = r.closedAt;
        }
        return true;
    }

    public synchronized boolean entrarNaSala(String roomCode, String ra, String name, String role) {
        Room r = obterOuCriarSala(roomCode);
        String normalizedRole = role != null ? role.trim().toLowerCase(Locale.ROOT) : "aluno";
        if (!r.isOpen) {
            if ("docente".equals(normalizedRole) || "admin".equals(normalizedRole)) {
                abrirSala(roomCode, normalizedRole, name);
            } else {
                return false;
            }
        }
        Participant p = new Participant(ra, name, normalizedRole);
        r.activeParticipants.put(ra, p);
        r.attendanceHistory.add(p);
        r.peerSignalQueues.putIfAbsent(ra, new ConcurrentLinkedQueue<SignalingMessage>());
        for (String otherRa : r.activeParticipants.keySet()) {
            if (!otherRa.equals(ra)) {
                enviarSinalizacao(roomCode, ra, otherRa, "peer-joined",
                        "{\"ra\":\"" + ra + "\",\"name\":\"" + name + "\",\"role\":\"" + normalizedRole + "\"}");
            }
        }
        return true;
    }

    public synchronized void sairDaSala(String roomCode, String ra) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null) return;
        Participant p = r.activeParticipants.remove(ra);
        if (p != null) {
            p.leftAt = System.currentTimeMillis();
        }
        r.handRaiseQueue.remove(ra);
        r.peerSignalQueues.remove(ra);
        for (String otherRa : r.activeParticipants.keySet()) {
            enviarSinalizacao(roomCode, ra, otherRa, "peer-left", "{\"ra\":\"" + ra + "\"}");
        }
    }

    public void enviarSinalizacao(String roomCode, String fromRa, String toRa, String type, String data) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null) return;
        Queue<SignalingMessage> queue = r.peerSignalQueues.get(toRa);
        if (queue != null) {
            queue.add(new SignalingMessage(fromRa, toRa, type, data));
        }
    }

    public List<SignalingMessage> buscarSinalizacoes(String roomCode, String ra) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null) return Collections.emptyList();
        Queue<SignalingMessage> queue = r.peerSignalQueues.get(ra);
        if (queue == null) return Collections.emptyList();
        List<SignalingMessage> messages = new ArrayList<SignalingMessage>();
        SignalingMessage msg;
        while ((msg = queue.poll()) != null) {
            messages.add(msg);
        }
        return messages;
    }

    public synchronized boolean alternarMaoLevantada(String roomCode, String ra, boolean levantar) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null) return false;
        Participant p = r.activeParticipants.get(ra);
        if (p == null) return false;
        p.isHandRaised = levantar;
        if (levantar) {
            p.handRaisedAt = System.currentTimeMillis();
            if (!r.handRaiseQueue.contains(ra)) {
                r.handRaiseQueue.add(ra);
            }
        } else {
            r.handRaiseQueue.remove(ra);
        }
        return true;
    }

    public synchronized void adicionarMensagemChat(
            String roomCode, String senderRa, String senderName, String senderRole, String text) {
        Room r = rooms.get(roomCode.trim().toUpperCase(Locale.ROOT));
        if (r == null) return;
        r.chatHistory.add(new ChatMessage(senderRa, senderName, senderRole, text));
    }
}
