// Desenvolvido por Guilherme Henrique Moreira

package database;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

// Gerencia a conexao com o MongoDB Atlas.
public class MongoDBConnection {

    private static MongoClient cliente;

    // Cria a conexao somente uma vez.
    public static synchronized MongoDatabase conectar() {
        if (cliente == null) {
            // Conexao temporaria com MongoDB Atlas
            String uri = "mongodb+srv://guilhermehmoreira2020_db_user:qaznEL4neMI86rXx@cluster0.yo4sjnv.mongodb.net/?appName=Cluster0";
            cliente = MongoClients.create(uri);
        }

        MongoDatabase banco = cliente.getDatabase("agmr");

        // Verifica se o banco esta respondendo.
        banco.runCommand(new Document("ping", 1));

        System.out.println("[MongoDB] Conexao estabelecida com sucesso!");
        return banco;
    }

    // Encerra a conexao ao finalizar a aplicacao.
    public static synchronized void fechar() {
        if (cliente != null) {
            cliente.close();
            cliente = null;
        }
    }

    // Permite testar a conexao sem iniciar o servidor HTTP.
    public static void main(String[] args) {
        try {
            conectar();
            System.out.println("[MongoDB] Banco agmr conectado!");
        } catch (Exception e) {
            System.err.println("[MongoDB] Erro na conexao: " + e.getMessage());
        } finally {
            fechar();
        }
    }
}