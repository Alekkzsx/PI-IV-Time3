// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323
package videocall;

import auth.DatabaseUnavailableException;
import auth.OtpService;
import auth.RepositorioUsuarios;
import auth.UsuarioAutenticado;
import com.mongodb.MongoCommandException;
import com.mongodb.MongoException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import com.mongodb.client.result.DeleteResult;
import org.bson.Document;
import org.bson.conversions.Bson;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Repositorio persistido em MongoDB para sessoes ao vivo de videochamada,
 * tickets WebSocket single-use e logs de presenca/telemetria.
 */
public class RepositorioVideoCall {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static volatile RepositorioVideoCall INSTANCIA;
    private static volatile boolean INDICES_INICIALIZADOS = false;

    private volatile MongoDatabase fixedDatabase;
    private volatile MongoCollection<Document> liveSessions;
    private volatile MongoCollection<Document> wsTickets;
    private volatile MongoCollection<Document> attendanceLogs;

    public static RepositorioVideoCall getInstance() {
        if (INSTANCIA == null) {
            synchronized (RepositorioVideoCall.class) {
                if (INSTANCIA == null) {
                    INSTANCIA = new RepositorioVideoCall(RepositorioUsuarios.getInstance().getDatabase());
                }
            }
        }
        return INSTANCIA;
    }

    public static RepositorioVideoCall getInstanciaSeBancoAtivo() {
        if (INSTANCIA != null) return INSTANCIA;
        RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
        if (repo == null || repo.getDatabase() == null) return null;
        return getInstance();
    }

    public RepositorioVideoCall(MongoDatabase database) {
        this.fixedDatabase = database;
        vincularColecoes(database);
    }

    private void vincularColecoes(MongoDatabase db) {
        MongoDatabase alvo = db;
        if (alvo == null) {
            RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
            if (repo != null) {
                alvo = repo.getDatabase();
            }
        }
        if (alvo == null) {
            return;
        }
        this.liveSessions = alvo.getCollection("academic_live_sessions");
        this.wsTickets = alvo.getCollection("video_call_ws_tickets");
        this.attendanceLogs = alvo.getCollection("video_call_attendance_logs");
        inicializarIndicesAsync();
    }

    private void garantirColecoes() {
        if (this.liveSessions != null) return;
        vincularColecoes(this.fixedDatabase);
        if (this.liveSessions == null) {
            throw new DatabaseUnavailableException(
                    503,
                    "database_network_blocked",
                    "Banco de dados inacessivel a partir desta rede.",
                    null
            );
        }
    }

    private void inicializarIndicesAsync() {
        if (INDICES_INICIALIZADOS || this.wsTickets == null || this.liveSessions == null) {
            return;
        }
        final MongoCollection<Document> ticketsCol = this.wsTickets;
        final MongoCollection<Document> liveCol = this.liveSessions;
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                synchronized (RepositorioVideoCall.class) {
                    if (INDICES_INICIALIZADOS) return;
                    criarIndice(ticketsCol, "idx_vc_tickets_digest_unique",
                            new Document("tokenDigest", 1), new IndexOptions().unique(true));
                    criarIndice(ticketsCol, "idx_vc_tickets_expiresat",
                            new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
                    criarIndice(liveCol, "idx_vc_live_expiresat",
                            new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
                    INDICES_INICIALIZADOS = true;
                }
            }
        }, "vc-indexes-init");
        t.setDaemon(true);
        t.start();
    }

    public static String sanitizeRoomCode(String raw) {
        if (raw == null) return "";
        return raw.trim()
                .toUpperCase(Locale.ROOT)
                .replaceAll("\\s*-\\s*", "-")
                .replaceAll("\\s+", "-")
                .replaceAll("[^A-Z0-9._-]", "");
    }

    public Set<String> listarCodigosSalasAbertas() {
        garantirColecoes();
        Set<String> abertas = new HashSet<String>();
        List<Document> docs = new ArrayList<Document>();
        try {
            liveSessions.find(Filters.gt("expiresAt", new Date())).into(docs);
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
        for (Document doc : docs) {
            String rc = doc.getString("roomCode");
            if (rc != null) {
                abertas.add(rc.toUpperCase(Locale.ROOT));
            }
        }
        return abertas;
    }

    public boolean salaEstaAberta(String roomCode) {
        garantirColecoes();
        String normalizado = sanitizeRoomCode(roomCode);
        try {
            Document ativo = liveSessions.find(
                    Filters.and(Filters.eq("roomCode", normalizado), Filters.gt("expiresAt", new Date()))
            ).first();
            return ativo != null;
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    public void abrirSala(String roomCode, String classCode, UsuarioAutenticado usuario) {
        garantirColecoes();
        String normalizado = sanitizeRoomCode(roomCode);
        Date agora = new Date();
        Date expira = new Date(agora.getTime() + 8L * 60L * 60L * 1000L);
        String identity = usuario.getIdentity().trim().toLowerCase(Locale.ROOT);
        String displayName = !usuario.getDisplayName().isEmpty() ? usuario.getDisplayName() : identity;

        try {
            liveSessions.updateOne(
                    Filters.eq("roomCode", normalizado),
                    Updates.combine(
                            Updates.set("roomCode", normalizado),
                            Updates.set("classCode", classCode),
                            Updates.set("openedById", usuario.getUserId()),
                            Updates.set("openedByIdentity", identity),
                            Updates.set("openedByName", displayName),
                            Updates.set("openedAt", agora),
                            Updates.set("expiresAt", expira)
                    ),
                    new UpdateOptions().upsert(true)
            );
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    public boolean fecharSala(String roomCode, UsuarioAutenticado usuario) {
        garantirColecoes();
        String normalizado = sanitizeRoomCode(roomCode);
        Bson filtro = usuario.isAdmin()
                ? Filters.eq("roomCode", normalizado)
                : Filters.and(Filters.eq("roomCode", normalizado), Filters.eq("openedById", usuario.getUserId()));
        try {
            DeleteResult result = liveSessions.deleteOne(filtro);
            return result.getDeletedCount() == 1;
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    public String emitirTicketWebSocket(String roomCode) {
        garantirColecoes();
        String normalizado = sanitizeRoomCode(roomCode);
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String ticket = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        String tokenDigest = OtpService.sha256Hex(ticket);
        try {
            wsTickets.insertOne(new Document()
                    .append("tokenDigest", tokenDigest)
                    .append("roomCode", normalizado)
                    .append("expiresAt", new Date(System.currentTimeMillis() + 60_000L)));
            return ticket;
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    public boolean consumirTicketWebSocket(String ticket, String roomCode) {
        if (ticket == null || !ticket.matches("^[A-Za-z0-9_-]{43}$")) {
            return false;
        }
        String normalizado = sanitizeRoomCode(roomCode);
        if (normalizado.isEmpty()) {
            return false;
        }
        garantirColecoes();
        String tokenDigest = OtpService.sha256Hex(ticket);
        try {
            Document consumed = wsTickets.findOneAndDelete(
                    Filters.and(
                            Filters.eq("tokenDigest", tokenDigest),
                            Filters.eq("roomCode", normalizado),
                            Filters.gt("expiresAt", new Date())
                    )
            );
            return consumed != null;
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    public void registrarLogPresenca(
            String roomCode,
            String classCode,
            UsuarioAutenticado usuario,
            String event,
            int connectedSeconds) {
        garantirColecoes();
        try {
            attendanceLogs.insertOne(new Document()
                    .append("roomCode", sanitizeRoomCode(roomCode))
                    .append("classCode", classCode)
                    .append("userId", usuario.getUserId())
                    .append("identity", usuario.getIdentity())
                    .append("displayName", usuario.getDisplayName())
                    .append("profile", usuario.getProfile())
                    .append("event", event)
                    .append("connectedSeconds", Integer.valueOf(Math.max(0, connectedSeconds)))
                    .append("recordedAt", new Date()));
        } catch (MongoException e) {
            throw DatabaseUnavailableException.fromThrowable(e);
        }
    }

    private static void criarIndice(MongoCollection<Document> col, String nome, Document keys, IndexOptions opts) {
        try {
            if (opts == null) opts = new IndexOptions();
            opts.name(nome);
            col.createIndex(keys, opts);
        } catch (MongoCommandException ignored) {
            // Indice ja existente com definicao compativel ou criada pelo backend
        } catch (Exception ignored) { }
    }
}
