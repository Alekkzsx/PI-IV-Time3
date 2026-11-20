// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
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
    // Singleton DCL; compartilha a ConexaoMongo do dominio auth (um pool so por processo).
    private static volatile RepositorioVideoCall INSTANCIA;

    /** Singleton padrao: reaproveita a conexao do RepositorioUsuarios (ou o database direto). */
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

    /** @return instancia somente se ja houver banco utilizavel; nunca dispara conexao (caminho do upgrade WS). */
    public static RepositorioVideoCall getInstanciaSeBancoAtivo() {
        if (INSTANCIA != null) return INSTANCIA;
        RepositorioUsuarios repo = RepositorioUsuarios.getInstanciaSeInicializada();
        if (repo == null || repo.getDatabase() == null) return null;
        return getInstance();
    }

    /** Modo producao: conexao compartilhada + indices em thread daemon. */
    public RepositorioVideoCall(ConexaoMongo conexao) {
        super(conexao);
        inicializarIndicesAsync("vc-indexes-init");
    }

    /** Modo banco fixo (testes/injecao). */
    public RepositorioVideoCall(MongoDatabase database) {
        super(database);
        inicializarIndicesAsync("vc-indexes-init");
    }

    @Override
    protected String tagLog() {
        return "VIDEOCALL-DB";
    }

    /**
     * Indices das 3 colecoes: ticket com digest unico + TTL (60s de vida util),
     * sessao ao vivo com TTL (expira em 8h mesmo sem fechamento explicito).
     */
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

    /** Delegador de compatibilidade: sanitizacao canonica vive em VideoCallUtils. */
    public static String sanitizeRoomCode(String raw) {
        return VideoCallUtils.sanitizeRoomCode(raw);
    }

    /** Codigos (uppercase) das salas com sessao nao expirada - usado para marcar isOpen na listagem. */
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

    /** Sala aberta = documento em academic_live_sessions com expiresAt no futuro. */
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

    /**
     * Abre (ou reabre) a sala via upsert por roomCode: registra quem abriu e renova
     * a janela de 8h. Reabrir pelo mesmo docente atualiza os metadados sem duplicar.
     */
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

    /**
     * Fecha a sala com guarda de POSSE no proprio filtro: docente so apaga a sessao
     * que ele abriu (openedById); admin apaga qualquer uma. deletedCount != 1 = nao fechou.
     */
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

    /**
     * Emite ticket de upgrade WS: 32 bytes SecureRandom em Base64URL (43 chars).
     * O banco guarda apenas o SHA-256 do ticket (vazamento do Mongo nao permite usar
     * tickets pendentes) com TTL de 60s - janela curta entre o enter e o upgrade.
     */
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

    /**
     * Consumo ATOMICO single-use (findOneAndDelete) casando digest + sala + validade.
     * Replay do mesmo ticket, ticket de outra sala ou expirado -> false.
     */
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

    /** Log append-only de telemetria (join/leave + segundos conectado) para auditoria de presenca. */
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
