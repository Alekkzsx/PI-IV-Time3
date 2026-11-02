// Desenvolvido por Guilherme Henrique Moreira

package database;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;
import utils.ConfigEnv;

// Gerencia a conexao com o MongoDB Atlas.
public class MongoDBConnection {

    private static MongoClient cliente;

    // Cria a conexao somente uma vez.
    public static synchronized MongoDatabase conectar() {
        if (cliente == null) {
            // A URI do Atlas vem de MONGODB_URI (variavel de ambiente ou arquivo env).
            cliente = MongoClients.create(ConfigEnv.exigir("MONGODB_URI"));
        }

        MongoDatabase banco = cliente.getDatabase(ConfigEnv.obter("MONGODB_DATABASE", "agmr"));

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
            System.out.println("[MongoDB] Banco " + ConfigEnv.obter("MONGODB_DATABASE", "agmr") + " conectado!");
        } catch (Exception e) {
            System.err.println("[MongoDB] Erro na conexao: " + e.getMessage());
        } finally {
            fechar();
        }
    }
}