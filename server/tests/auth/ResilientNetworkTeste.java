package auth;

import com.mongodb.MongoTimeoutException;
import com.mongodb.spi.dns.DnsException;
import core.RequisicaoHttp;
import core.RespostaHttp;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Testes unitarios de resiliencia de rede/DNS (Wi-Fi corporativo e universitario).
 */
public class ResilientNetworkTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    private static final class RepoBancoBloqueado extends RepositorioUsuarios {
        RepoBancoBloqueado() {
            super(false);
        }

        @Override
        public UsuarioAutenticado autenticar(String identidade, String senha) {
            throw DatabaseUnavailableException.fromThrowable(
                    new MongoTimeoutException("Timed out after 5000 ms while waiting for a server")
            );
        }
    }

    public static int executar() {
        falhas = 0;
        try {
            String srvJson = "{\"Status\":0,\"Answer\":["
                    + "{\"name\":\"_mongodb._tcp.cluster0.example.mongodb.net.\",\"type\":33,\"data\":\"0 0 27017 shard-00-00.example.mongodb.net.\"},"
                    + "{\"name\":\"_mongodb._tcp.cluster0.example.mongodb.net.\",\"type\":33,\"data\":\"0 0 27017 shard-00-01.example.mongodb.net.\"}"
                    + "]}";
            List<String> srvRecords = ResilientDnsClient.parseDohResponse(srvJson, "SRV");
            esperar(srvRecords.size() == 2
                            && "0 0 27017 shard-00-00.example.mongodb.net.".equals(srvRecords.get(0)),
                    "ResilientDnsClient: analisa registros SRV DoH no formato esperado pelo driver MongoDB");

            String txtJson = "{\"Status\":0,\"Answer\":["
                    + "{\"name\":\"cluster0.example.mongodb.net.\",\"type\":16,\"data\":\"\\\"authSource=admin\\\" \\\"&replicaSet=atlas-xyz\\\"\"}"
                    + "]}";
            List<String> txtRecords = ResilientDnsClient.parseDohResponse(txtJson, "TXT");
            esperar(txtRecords.size() == 1
                            && "authSource=admin&replicaSet=atlas-xyz".equals(txtRecords.get(0)),
                    "ResilientDnsClient: normaliza segmentos TXT DoH removendo aspas");

            DatabaseUnavailableException dnsEx = DatabaseUnavailableException.fromThrowable(
                    new DnsException("DNS lookup blocked", null)
            );
            esperar(dnsEx.getStatusHttp() == 503 && "database_dns_blocked".equals(dnsEx.getCodigo()),
                    "DatabaseUnavailableException: classifica falha DNS SRV como 503 database_dns_blocked");

            DatabaseUnavailableException netEx = DatabaseUnavailableException.fromThrowable(
                    new MongoTimeoutException("Timed out connecting to 27017")
            );
            esperar(netEx.getStatusHttp() == 503 && "database_network_blocked".equals(netEx.getCodigo()),
                    "DatabaseUnavailableException: classifica timeout TCP 27017 como 503 database_network_blocked");

            LoginHandler loginHandler = new LoginHandler(new RepoBancoBloqueado());
            String jsonBody = "{\"identity\":\"aluno.test\",\"password\":\"Agmrm@2026\",\"profile\":\"aluno\"}";
            byte[] bodyBytes = jsonBody.getBytes(StandardCharsets.UTF_8);
            String rawReq = "POST /api/auth/login HTTP/1.1\r\n"
                    + "Host: 127.0.0.1:8080\r\n"
                    + "Content-Type: application/json\r\n"
                    + "Content-Length: " + bodyBytes.length + "\r\n\r\n"
                    + jsonBody;
            RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(rawReq.getBytes(StandardCharsets.UTF_8)));
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            RespostaHttp resp = new RespostaHttp(out);
            loginHandler.handle(req, resp);
            String httpResp = new String(out.toByteArray(), StandardCharsets.UTF_8);

            esperar(httpResp.startsWith("HTTP/1.1 503")
                            && httpResp.contains("\"code\":\"database_network_blocked\""),
                    "LoginHandler: retorna HTTP 503 diagnostico (nao 401/lockout) quando MongoDB esta bloqueado");
        } catch (Exception e) {
            esperar(false, "ResilientNetworkTeste sem excecoes: " + e.getMessage());
        }
        return falhas;
    }
}
