// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.persistencia;

import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Updates;
import core.ConexaoMongo;
import core.abstratas.RepositorioMongoAbstrato;
import org.bson.Document;

import java.util.Date;
import java.util.concurrent.TimeUnit;

/**
 * Repositorio especializado na colecao auth_otps (codigos OTP de 2FA/recuperacao e grants single-use).
 */
public class RepositorioOtps extends RepositorioMongoAbstrato {

    public RepositorioOtps(ConexaoMongo conexao) {
        super(conexao);
    }

    @Override
    protected String tagLog() {
        return "AUTH-OTPS";
    }

    @Override
    protected void registrarIndices(MongoDatabase db) {
        MongoCollection<Document> otps = db.getCollection("auth_otps");
        criarIndiceSeguro(otps, "idx_auth_otps_identity", new Document("identity", 1), null);
        criarIndiceSeguro(otps, "idx_auth_otps_expiresat",
                new Document("expiresAt", 1), new IndexOptions().expireAfter(0L, TimeUnit.SECONDS));
    }

    public MongoCollection<Document> colecaoOtpsSeAtiva() {
        return obterColecaoSeAtiva("auth_otps");
    }

    public void salvarOtp(String identity, String otpHash, String tipo, long expiresAtMillis) {
        try {
            MongoCollection<Document> col = obterColecao("auth_otps");
            String norm = identity.toLowerCase();
            col.deleteMany(Filters.and(Filters.eq("identity", norm), Filters.eq("tipo", tipo)));
            col.insertOne(new Document()
                    .append("identity", norm)
                    .append("otpHash", otpHash)
                    .append("tipo", tipo)
                    .append("tentativas", 0)
                    .append("createdAt", new Date())
                    .append("expiresAt", new Date(expiresAtMillis)));
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao salvar OTP: " + e.getMessage());
        }
    }

    public Document buscarOtp(String identity, String tipo) {
        try {
            return obterColecao("auth_otps").find(
                    Filters.and(Filters.eq("identity", identity.toLowerCase()), Filters.eq("tipo", tipo))
            ).sort(new Document("createdAt", -1)).first();
        } catch (Exception e) {
            return null;
        }
    }

    public void incrementarTentativasOtp(String identity, String tipo) {
        try {
            obterColecao("auth_otps").updateOne(
                    Filters.and(Filters.eq("identity", identity.toLowerCase()), Filters.eq("tipo", tipo)),
                    Updates.inc("tentativas", 1)
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao incrementar tentativas OTP: " + e.getMessage());
        }
    }

    public void removerOtp(String identity, String tipo) {
        try {
            obterColecao("auth_otps").deleteMany(
                    Filters.and(Filters.eq("identity", identity.toLowerCase()), Filters.eq("tipo", tipo))
            );
        } catch (Exception e) {
            System.err.println("[AUTH] Erro ao remover OTP: " + e.getMessage());
        }
    }

    public void emitirGrantRecuperacao(String normalizedIdentity, String jtiHash, long expiresAtMillis) {
        salvarOtp(normalizedIdentity, jtiHash, "RESET_GRANT", expiresAtMillis);
    }

    public boolean consumirGrantRecuperacao(String jtiHash) {
        if (jtiHash == null || jtiHash.isEmpty()) {
            return false;
        }
        try {
            Document consumed = obterColecao("auth_otps").findOneAndDelete(
                    Filters.and(
                            Filters.eq("tipo", "RESET_GRANT"),
                            Filters.eq("otpHash", jtiHash),
                            Filters.gt("expiresAt", new Date())
                    )
            );
            return consumed != null;
        } catch (Exception e) {
            return false;
        }
    }
}
