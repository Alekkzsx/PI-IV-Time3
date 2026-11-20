// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.persistencia;

import auth.modules.email.SmtpCliente;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Sorts;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import core.ConexaoMongo;
import core.abstratas.RepositorioMongoAbstrato;
import org.bson.Document;
import org.bson.types.ObjectId;
import utils.BsonUtils;

import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Repositorio especializado em auditoria de seguranca (admin_audit_logs),
 * write-guard administrativo (admin_write_guard) e indice TTL de email_outbox.
 */
public class RepositorioAuditoria extends RepositorioMongoAbstrato {

    public RepositorioAuditoria(ConexaoMongo conexao) {
        super(conexao);
    }

    @Override
    protected String tagLog() {
        return "AUTH-AUDITORIA";
    }

    @Override
    protected void registrarIndices(MongoDatabase db) {
        criarIndiceSeguro(db.getCollection("admin_audit_logs"),
                "idx_admin_audit_logs_createdat", new Document("createdAt", -1), null);
        criarIndiceSeguro(db.getCollection("email_outbox"),
                "idx_email_outbox_expiresat", new Document("expiresAt", 1),
                new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
    }

    public MongoCollection<Document> colecaoAuditoriaSeAtiva() {
        return obterColecaoSeAtiva("admin_audit_logs");
    }

    public MongoCollection<Document> colecaoWriteGuardSeAtiva() {
        return obterColecaoSeAtiva("admin_write_guard");
    }

    public MongoCollection<Document> colecaoEmailOutboxSeAtiva() {
        return obterColecaoSeAtiva("email_outbox");
    }

    public void registrarAuditoria(
            String actorId, String action, String target, Map<String, Object> details, String ipAddress) {
        try {
            Document doc = new Document()
                    .append("actorId", actorId != null ? actorId : "system")
                    .append("action", action)
                    .append("target", target != null ? target : "")
                    .append("details", details != null ? BsonUtils.mapaParaDocumento(details) : new Document())
                    .append("createdAt", new Date());
            if (ipAddress != null && !ipAddress.trim().isEmpty()) {
                doc.append("ipAddress", ipAddress.trim());
            }
            obterColecao("admin_audit_logs").insertOne(doc);
        } catch (Exception e) {
            System.err.println("[AUDIT] Erro ao registrar auditoria: " + e.getMessage());
        }
    }

    public void registrarResultadoEnvioEmail(
            String actorId,
            String eventoBase,
            String destinatario,
            SmtpCliente.ResultadoEnvioEmail resultado,
            Throwable erro) {
        String destino = destinatario != null ? destinatario : "";
        Map<String, Object> det = new LinkedHashMap<String, Object>();
        det.put("recipient", destino);
        if (erro != null) {
            det.put("error", erro.getMessage() != null ? erro.getMessage() : erro.getClass().getSimpleName());
            registrarAuditoria(actorId, eventoBase + "_failed", destino, det, null);
            return;
        }
        if (resultado == null) {
            registrarAuditoria(actorId, eventoBase + "_failed", destino, det, null);
            return;
        }
        det.put("channel", resultado.getCanal());
        det.put("deliveredExternally", Boolean.valueOf(resultado.isDeliveredExternally()));
        det.put("latencyMs", Long.valueOf(resultado.getLatenciaMs()));
        if (!resultado.getErrorTrail().isEmpty()) {
            det.put("errorTrail", resultado.getErrorTrail());
        }
        String action = resultado.isDeliveredExternally() ? eventoBase + "_sent" : eventoBase + "_outbox";
        registrarAuditoria(actorId, action, destino, det, null);
    }

    public List<Document> listarLogsSeguranca(String userId, int limit) {
        List<Document> logs = new ArrayList<Document>();
        try {
            obterColecao("admin_audit_logs").find(
                    Filters.or(Filters.eq("actorId", userId), Filters.eq("target", userId))
            ).sort(Sorts.descending("createdAt")).limit(limit).into(logs);
        } catch (Exception e) {
            System.err.println("[AUDIT] Erro ao listar logs de seguranca: " + e.getMessage());
        }
        return logs;
    }

    public boolean registrarEscritaAdmin(String adminId) {
        if (adminId == null || !ObjectId.isValid(adminId.trim())) {
            return false;
        }
        try {
            MongoDatabase db = garantirBancoAtivo();
            db.getCollection("admin_write_guard").updateOne(
                    Filters.eq("_id", "admin"),
                    Updates.inc("revision", 1),
                    new UpdateOptions().upsert(true)
            );
            Document adminDoc = db.getCollection("auth_users").find(
                    Filters.and(
                            Filters.eq("_id", new ObjectId(adminId.trim())),
                            Filters.eq("profile", "admin"),
                            Filters.eq("active", true)
                    )
            ).first();
            return adminDoc != null;
        } catch (Exception e) {
            return false;
        }
    }
}
