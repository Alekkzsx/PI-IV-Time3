// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323
package videocall.modules.rooms;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.OtpService;
import com.mongodb.MongoException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import com.mongodb.client.result.DeleteResult;
import core.ConexaoMongo;
import core.abstratas.RepositorioMongoAbstrato;
import org.bson.Document;
import org.bson.conversions.Bson;
import videocall.utils.VideoCallUtils;

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
public class RepositorioVideoCall extends RepositorioMongoAbstrato {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static volatile RepositorioVideoCall INSTANCIA;

    public static RepositorioVideoCall getInstance() {
        if (INSTANCIA == null) {
            synchronized (RepositorioVideoCall.class) {
                if (INSTANCIA == null) {
                    RepositorioUsuarios repoAuth = RepositorioUsuarios.getInstance();
                    ConexaoMongo conn = repoAuth.getConexao();
                    INSTANCIA = conn != null
                            ? new RepositorioVideoCall(conn)
                            : new RepositorioVideoCall(repoAuth.getDatabase());
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

    public RepositorioVideoCall(ConexaoMongo conexao) {
        super(conexao);
        inicializarIndicesAsync("vc-indexes-init");
    }

    public RepositorioVideoCall(MongoDatabase database) {
        super(database);
        inicializarIndicesAsync("vc-indexes-init");
    }

    @Override
    protected String tagLog() {
        return "VIDEOCALL-DB";
    }

    @Override
    protected void registrarIndices(MongoDatabase db) {
        MongoCollection<Document> ticketsCol = db.getCollection("video_call_ws_tickets");
        MongoCollection<Document> liveCol = db.getCollection("academic_live_sessions");
        criarIndiceSeguro(ticketsCol, "idx_vc_tickets_digest_unique",
                new Document("tokenDigest", 1), new IndexOptions().unique(true));
        criarIndiceSeguro(ticketsCol, "idx_vc_tickets_expiresat",
                new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
        criarIndiceSeguro(liveCol, "idx_vc_live_expiresat",
                new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
    }

    public static String sanitizeRoomCode(String raw) {
        return VideoCallUtils.sanitizeRoomCode(raw);
    }

    public Set<String> listarCodigosSalasAbertas() {
        Set<String> abertas = new HashSet<String>();
        List<Document> docs = new ArrayList<Document>();
        try {
            obterColecao("academic_live_sessions").find(Filters.gt("expiresAt", new Date())).into(docs);
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "listarCodigosSalasAbertas");
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
        String normalizado = VideoCallUtils.sanitizeRoomCode(roomCode);
        try {
            Document ativo = obterColecao("academic_live_sessions").find(
                    Filters.and(Filters.eq("roomCode", normalizado), Filters.gt("expiresAt", new Date()))
            ).first();
            return ativo != null;
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "salaEstaAberta");
        }
    }

    public void abrirSala(String roomCode, String classCode, UsuarioAutenticado usuario) {
        String normalizado = VideoCallUtils.sanitizeRoomCode(roomCode);
        Date agora = new Date();
        Date expira = new Date(agora.getTime() + 8L * 60L * 60L * 1000L);
        String identity = usuario.getIdentity().trim().toLowerCase(Locale.ROOT);
        String displayName = !usuario.getDisplayName().isEmpty() ? usuario.getDisplayName() : identity;

        try {
            obterColecao("academic_live_sessions").updateOne(
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
            throw tratarFalhaMongo(e, "abrirSala");
        }
    }

    public boolean fecharSala(String roomCode, UsuarioAutenticado usuario) {
        String normalizado = VideoCallUtils.sanitizeRoomCode(roomCode);
        Bson filtro = usuario.isAdmin()
                ? Filters.eq("roomCode", normalizado)
                : Filters.and(Filters.eq("roomCode", normalizado), Filters.eq("openedById", usuario.getUserId()));
        try {
            DeleteResult result = obterColecao("academic_live_sessions").deleteOne(filtro);
            return result.getDeletedCount() == 1;
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "fecharSala");
        }
    }

    public String emitirTicketWebSocket(String roomCode) {
        String normalizado = VideoCallUtils.sanitizeRoomCode(roomCode);
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String ticket = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        String tokenDigest = OtpService.sha256Hex(ticket);
        try {
            obterColecao("video_call_ws_tickets").insertOne(new Document()
                    .append("tokenDigest", tokenDigest)
                    .append("roomCode", normalizado)
                    .append("expiresAt", new Date(System.currentTimeMillis() + 60_000L)));
            return ticket;
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "emitirTicketWebSocket");
        }
    }

    public boolean consumirTicketWebSocket(String ticket, String roomCode) {
        if (ticket == null || !ticket.matches("^[A-Za-z0-9_-]{43}$")) {
            return false;
        }
        String normalizado = VideoCallUtils.sanitizeRoomCode(roomCode);
        if (normalizado.isEmpty()) {
            return false;
        }
        String tokenDigest = OtpService.sha256Hex(ticket);
        try {
            Document consumed = obterColecao("video_call_ws_tickets").findOneAndDelete(
                    Filters.and(
                            Filters.eq("tokenDigest", tokenDigest),
                            Filters.eq("roomCode", normalizado),
                            Filters.gt("expiresAt", new Date())
                    )
            );
            return consumed != null;
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "consumirTicketWebSocket");
        }
    }

    public void registrarLogPresenca(
            String roomCode, String classCode, UsuarioAutenticado usuario, String event, int connectedSeconds) {
        try {
            obterColecao("video_call_attendance_logs").insertOne(new Document()
                    .append("roomCode", VideoCallUtils.sanitizeRoomCode(roomCode))
                    .append("classCode", classCode)
                    .append("userId", usuario.getUserId())
                    .append("identity", usuario.getIdentity())
                    .append("displayName", usuario.getDisplayName())
                    .append("profile", usuario.getProfile())
                    .append("event", event)
                    .append("connectedSeconds", Integer.valueOf(Math.max(0, connectedSeconds)))
                    .append("recordedAt", new Date()));
        } catch (MongoException e) {
            throw tratarFalhaMongo(e, "registrarLogPresenca");
        }
    }
}
