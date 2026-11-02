// Desenvolvido por Marcelo Zarpelon

package database;

import com.mongodb.MongoWriteException;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Banco de documentos sobre o MongoDB Atlas; o campo "id" dos documentos vira o "_id" do Mongo.
public class BancoMongo implements BancoDados {
    private final MongoDatabase banco;

    public BancoMongo(MongoDatabase banco) { this.banco = banco; }

    @Override
    public Colecao colecao(String nome) { return new ColecaoMongo(banco.getCollection(nome)); }

    private static class ColecaoMongo implements Colecao {
        private final MongoCollection<Document> colecao;

        ColecaoMongo(MongoCollection<Document> colecao) { this.colecao = colecao; }

        // Documento do Mongo -> mapa da API (com "id" como primeiro campo).
        private static Map<String, Object> paraMapa(Document documento) {
            Map<String, Object> mapa = new LinkedHashMap<>();
            mapa.put("id", documento.get("_id"));
            for (Map.Entry<String, Object> campo : documento.entrySet()) {
                if (!campo.getKey().equals("_id")) mapa.put(campo.getKey(), campo.getValue());
            }
            return mapa;
        }

        // Mapa da API -> documento do Mongo (o "id" vira "_id").
        private static Document paraDocumento(Map<String, Object> mapa) {
            Document documento = new Document("_id", mapa.get("id"));
            for (Map.Entry<String, Object> campo : mapa.entrySet()) {
                if (!campo.getKey().equals("id")) documento.put(campo.getKey(), campo.getValue());
            }
            return documento;
        }

        @Override
        public List<Map<String, Object>> listar(Map<String, String> filtro) {
            Document consulta = new Document();
            for (Map.Entry<String, String> condicao : filtro.entrySet()) {
                consulta.put(condicao.getKey().equals("id") ? "_id" : condicao.getKey(), condicao.getValue());
            }
            List<Map<String, Object>> resultado = new ArrayList<>();
            for (Document documento : colecao.find(consulta)) resultado.add(paraMapa(documento));
            return resultado;
        }

        @Override
        public Map<String, Object> buscar(String id) {
            Document documento = colecao.find(new Document("_id", id)).first();
            return documento == null ? null : paraMapa(documento);
        }

        @Override
        public void inserir(Map<String, Object> documento) {
            try {
                colecao.insertOne(paraDocumento(documento));
            } catch (MongoWriteException e) {
                // Codigo 11000 = chave duplicada.
                if (e.getError().getCode() == 11000) throw new IdDuplicadoException(String.valueOf(documento.get("id")));
                throw e;
            }
        }

        @Override
        public boolean substituir(String id, Map<String, Object> documento) {
            return colecao.replaceOne(new Document("_id", id), paraDocumento(documento)).getMatchedCount() > 0;
        }

        @Override
        public boolean remover(String id) {
            return colecao.deleteOne(new Document("_id", id)).getDeletedCount() > 0;
        }
    }
}
