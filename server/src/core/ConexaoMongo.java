// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core;

import com.mongodb.Block;
import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.MongoException;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import com.mongodb.connection.ClusterSettings;
import com.mongodb.connection.SocketSettings;
import org.bson.Document;
import utils.ConfigEnv;

import java.util.concurrent.TimeUnit;

/**
 * Gerenciador central da conexao MongoDB do servidor Java.
 * Responsavel por DNS resiliente (DoH), failover automatico SRV -> MONGODB_DIRECT_URI,
 * cache de healthcheck e encerramento limpo do pool no shutdown.
 */
public class ConexaoMongo {
    private static final int SERVER_SELECTION_TIMEOUT_MS = 5_000;
    private static final int SOCKET_TIMEOUT_MS = 10_000;
    private static final long HEALTH_CACHE_TTL_MS = 5_000L;

    public static final class EstadoSaudeBanco {
        public final boolean disponivel;
        public final String codigo;
        public final String detalhe;

        public EstadoSaudeBanco(boolean disponivel, String codigo, String detalhe) {
            this.disponivel = disponivel;
            this.codigo = codigo;
            this.detalhe = detalhe;
        }
    }

    private static volatile ConexaoMongo INSTANCIA;

    private volatile MongoClient client;
    private volatile MongoDatabase database;
    private final String dbNameConfigurado;
    private final String uriPrincipalConfigurada;
    private final String uriDiretaConfigurada;
    private final ResilientDnsClient dnsClient = new ResilientDnsClient();
    private volatile boolean usandoUriDireta = false;
    private volatile long ultimoCheckSaudeAt = 0L;
    private volatile boolean ultimoCheckSaudeOk = false;
    private volatile String ultimoErroBancoCodigo = "";
    private volatile String ultimoErroBancoMsg = "";

    public static ConexaoMongo getInstance() {
        if (INSTANCIA == null) {
            synchronized (ConexaoMongo.class) {
                if (INSTANCIA == null) {
                    INSTANCIA = new ConexaoMongo();
                }
            }
        }
        return INSTANCIA;
    }

    public static ConexaoMongo getInstanciaSeInicializada() {
        return INSTANCIA;
    }

    public ConexaoMongo() {
        String uri = ConfigEnv.obter("MONGODB_URI", null);
        String directUri = ConfigEnv.obter("MONGODB_DIRECT_URI", null);
        if ((uri == null || uri.trim().isEmpty()) && (directUri == null || directUri.trim().isEmpty())) {
            throw new IllegalStateException("MONGODB_URI nao configurado no .env");
        }
        this.dbNameConfigurado = ConfigEnv.obter("MONGODB_DATABASE", "agmrm");
        this.uriPrincipalConfigurada = (uri != null && !uri.trim().isEmpty()) ? uri.trim() : directUri.trim();
        this.uriDiretaConfigurada = (directUri != null && !directUri.trim().isEmpty()) ? directUri.trim() : null;

        System.out.println("[MONGO] Conectando ao MongoDB: " + dbNameConfigurado);
        inicializarCliente(this.uriPrincipalConfigurada, false);

        if (INSTANCIA == null) {
            INSTANCIA = this;
        }
        System.out.println("[MONGO] Cliente MongoDB inicializado com DNS resiliente e timeout rapido ("
                + SERVER_SELECTION_TIMEOUT_MS + "ms).");
    }

    private synchronized void inicializarCliente(String connectionUri, boolean direta) {
        if (connectionUri == null || connectionUri.trim().isEmpty()) {
            return;
        }
        MongoClient anterior = this.client;
        try {
            ConnectionString cs = new ConnectionString(connectionUri.trim());
            MongoClientSettings.Builder builder = MongoClientSettings.builder()
                    .applyConnectionString(cs)
                    .applyToClusterSettings(new Block<ClusterSettings.Builder>() {
                        @Override
                        public void apply(ClusterSettings.Builder cluster) {
                            cluster.serverSelectionTimeout(SERVER_SELECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                        }
                    })
                    .applyToSocketSettings(new Block<SocketSettings.Builder>() {
                        @Override
                        public void apply(SocketSettings.Builder socket) {
                            socket.connectTimeout(SERVER_SELECTION_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                                  .readTimeout(SOCKET_TIMEOUT_MS, TimeUnit.MILLISECONDS);
                        }
                    });
            if (connectionUri.trim().startsWith("mongodb+srv://")) {
                builder.dnsClient(this.dnsClient);
            }
            MongoClient novoClient = MongoClients.create(builder.build());
            this.client = novoClient;
            this.database = novoClient.getDatabase(this.dbNameConfigurado);
            this.usandoUriDireta = direta;
            if (anterior != null && anterior != novoClient) {
                try {
                    anterior.close();
                } catch (Exception ignored) { }
            }
        } catch (RuntimeException e) {
            if (!direta && this.uriDiretaConfigurada != null) {
                System.err.println("[MONGO] Falha na URI SRV principal (" + e.getMessage()
                        + "). Tentando MONGODB_DIRECT_URI...");
                inicializarCliente(this.uriDiretaConfigurada, true);
                return;
            }
            registrarIndisponibilidade(DatabaseUnavailableException.fromThrowable(e),
                    "Nao foi possivel inicializar cliente MongoDB no boot");
        }
    }

    public MongoDatabase getDatabase() {
        return database;
    }

    public MongoDatabase garantirBancoAtivo() {
        if (this.database == null) {
            if (this.uriPrincipalConfigurada != null) {
                inicializarCliente(this.uriPrincipalConfigurada, false);
            }
            if (this.database == null) {
                throw new DatabaseUnavailableException(
                        503,
                        this.ultimoErroBancoCodigo.isEmpty() ? "database_unavailable" : this.ultimoErroBancoCodigo,
                        this.ultimoErroBancoMsg.isEmpty()
                                ? "Banco de dados inacessivel a partir desta rede."
                                : this.ultimoErroBancoMsg,
                        null
                );
            }
        }
        return this.database;
    }

    /**
     * Verifica rapidamente (com cache de 5s) se o MongoDB esta acessivel na rede atual.
     */
    public EstadoSaudeBanco verificarSaudeBanco() {
        if (this.uriPrincipalConfigurada == null) {
            return new EstadoSaudeBanco(false, "database_unconfigured", "Repositorio offline.");
        }
        long agora = System.currentTimeMillis();
        if (agora - this.ultimoCheckSaudeAt < HEALTH_CACHE_TTL_MS && this.ultimoCheckSaudeAt > 0L) {
            return new EstadoSaudeBanco(this.ultimoCheckSaudeOk, this.ultimoErroBancoCodigo, this.ultimoErroBancoMsg);
        }
        if (this.database == null) {
            inicializarCliente(this.uriPrincipalConfigurada, false);
        }
        if (this.database == null) {
            this.ultimoCheckSaudeAt = agora;
            return new EstadoSaudeBanco(false, this.ultimoErroBancoCodigo, this.ultimoErroBancoMsg);
        }
        if (executarPing()) {
            return new EstadoSaudeBanco(true, "ok", "");
        }
        if (!this.usandoUriDireta && this.uriDiretaConfigurada != null) {
            inicializarCliente(this.uriDiretaConfigurada, true);
            if (this.database != null && executarPing()) {
                return new EstadoSaudeBanco(true, "ok", "");
            }
        }
        return new EstadoSaudeBanco(false, this.ultimoErroBancoCodigo, this.ultimoErroBancoMsg);
    }

    private boolean executarPing() {
        try {
            this.database.runCommand(new Document("ping", 1));
            this.ultimoCheckSaudeAt = System.currentTimeMillis();
            this.ultimoCheckSaudeOk = true;
            this.ultimoErroBancoCodigo = "";
            this.ultimoErroBancoMsg = "";
            return true;
        } catch (Exception e) {
            registrarIndisponibilidade(DatabaseUnavailableException.fromThrowable(e), "Ping MongoDB falhou");
            return false;
        }
    }

    public RuntimeException tratarFalhaMongo(MongoException e, String contexto) {
        if (!this.usandoUriDireta && this.uriDiretaConfigurada != null) {
            DatabaseUnavailableException prelim = DatabaseUnavailableException.fromThrowable(e);
            if ("database_dns_blocked".equals(prelim.getCodigo())) {
                System.err.println("[MONGO-NET] Falha DNS SRV em " + contexto + "; tentando MONGODB_DIRECT_URI...");
                inicializarCliente(this.uriDiretaConfigurada, true);
            }
        }
        DatabaseUnavailableException unavailable = DatabaseUnavailableException.fromThrowable(e);
        registrarIndisponibilidade(unavailable, contexto + " (" + e.getMessage() + ")");
        return unavailable;
    }

    private void registrarIndisponibilidade(DatabaseUnavailableException unavailable, String contexto) {
        this.ultimoCheckSaudeAt = System.currentTimeMillis();
        this.ultimoCheckSaudeOk = false;
        this.ultimoErroBancoCodigo = unavailable.getCodigo();
        this.ultimoErroBancoMsg = unavailable.getMessage();
        System.err.println("[MONGO-NET] " + contexto + ": " + unavailable.getMessage());
    }

    public void encerrarDefinitivo() {
        if (client != null) {
            client.close();
            System.out.println("[MONGO] Conexao MongoDB fechada em definitivo.");
        }
    }
}
