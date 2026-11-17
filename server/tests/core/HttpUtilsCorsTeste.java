package core;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Testes unitarios de CORS (origem unica, lista multi-valorada, loopback dev e Private Network Access).
 */
public class HttpUtilsCorsTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static int executar() {
        falhas = 0;
        String anteriorAllowed = System.getProperty("ALLOWED_ORIGINS");
        String anteriorNodeEnv = System.getProperty("NODE_ENV");
        String anteriorLan = System.getProperty("ALLOW_LAN_CORS");
        try {
            String lista8 = "http://localhost:3000,http://127.0.0.1:3000,http://localhost:5000,http://127.0.0.1:5000,http://localhost:8080,http://127.0.0.1:8080,http://localhost:8081,http://127.0.0.1:8081";

            String matched = HttpUtils.resolverOriginCors("http://localhost:5000", lista8, false, false);
            esperar("http://localhost:5000".equals(matched),
                    "HttpUtils: extrai uma unica origem quando ALLOWED_ORIGINS tem lista separada por virgula");

            String dynamicPort = HttpUtils.resolverOriginCors("http://localhost:54321", lista8, false, false);
            esperar("http://localhost:54321".equals(dynamicPort),
                    "HttpUtils: aceita porta dinamica de flutter run -d chrome em desenvolvimento");

            String ipv6Loopback = HttpUtils.resolverOriginCors("http://[::1]:5000", lista8, false, false);
            esperar("http://[::1]:5000".equals(ipv6Loopback),
                    "HttpUtils: aceita loopback IPv6 [::1] em desenvolvimento");

            String lanBlocked = HttpUtils.resolverOriginCors("http://192.168.15.20:5000", lista8, false, false);
            esperar(lanBlocked == null,
                    "HttpUtils: bloqueia IP LAN privado quando ALLOW_LAN_CORS=false");

            String lanAllowed = HttpUtils.resolverOriginCors("http://192.168.15.20:5000", lista8, false, true);
            esperar("http://192.168.15.20:5000".equals(lanAllowed),
                    "HttpUtils: aceita IP LAN privado quando ALLOW_LAN_CORS=true em dev");

            String prodDenied = HttpUtils.resolverOriginCors("http://localhost:54321", lista8, true, true);
            esperar(prodDenied == null,
                    "HttpUtils: em producao rejeita porta fora da lista explicita ALLOWED_ORIGINS");

            String wildcard = HttpUtils.resolverOriginCors("https://app.example.edu", "*", true, false);
            esperar("*".equals(wildcard),
                    "HttpUtils: preserva curinga * quando configurado explicitamente");

            System.setProperty("ALLOWED_ORIGINS", lista8);
            System.setProperty("NODE_ENV", "development");
            System.setProperty("ALLOW_LAN_CORS", "false");

            String rawReq = "OPTIONS /api/auth/login HTTP/1.1\r\n"
                    + "Host: 127.0.0.1:8080\r\n"
                    + "Origin: http://localhost:49152\r\n"
                    + "Access-Control-Request-Method: POST\r\n"
                    + "Access-Control-Request-Private-Network: true\r\n\r\n";
            RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(rawReq.getBytes(StandardCharsets.UTF_8)));
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            RespostaHttp resp = new RespostaHttp(out);
            HttpUtils.aplicarHeadersCors(req, resp);
            resp.enviar(204, "");
            String httpOut = new String(out.toByteArray(), StandardCharsets.UTF_8);

            esperar(httpOut.contains("Access-Control-Allow-Origin: http://localhost:49152\r\n"),
                    "Resposta OPTIONS: emite exatamente uma unica origem no header Access-Control-Allow-Origin");
            esperar(!httpOut.contains("http://localhost:3000,http://127.0.0.1:3000"),
                    "Resposta OPTIONS: nunca emite lista separada por virgula");
            esperar(httpOut.contains("Vary: Origin\r\n"),
                    "Resposta OPTIONS: inclui header Vary: Origin");
            esperar(httpOut.contains("Access-Control-Allow-Private-Network: true\r\n"),
                    "Resposta OPTIONS: inclui Access-Control-Allow-Private-Network em requisicao PNA");
        } catch (Exception e) {
            esperar(false, "HttpUtilsCorsTeste sem excecoes: " + e.getMessage());
        } finally {
            restaurarProp("ALLOWED_ORIGINS", anteriorAllowed);
            restaurarProp("NODE_ENV", anteriorNodeEnv);
            restaurarProp("ALLOW_LAN_CORS", anteriorLan);
        }
        return falhas;
    }

    private static void restaurarProp(String key, String previous) {
        if (previous == null) System.clearProperty(key);
        else System.setProperty(key, previous);
    }
}
