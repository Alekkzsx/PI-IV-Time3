// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.RequisicaoHttp;
import utils.ConfigEnv;
import utils.Json;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Validador JWT HS256 implementado 100% na unha com a biblioteca padrao do JDK (zero dependencias externas).
 * Confere assinatura HMAC-SHA256 em tempo constante, expiracao, perfil institucional e, opcionalmente,
 * revogacao de sessao ativa no backend TypeScript (/api/auth/me).
 */
public final class JwtAuthValidator {
    private static final String ALGORITMO_HMAC = "HmacSHA256";
    private static final int TIMEOUT_REMOTO_MS = 2500;
    private static final Set<String> PERFIS_VALIDOS = Collections.unmodifiableSet(
            new HashSet<String>(Arrays.asList("aluno", "docente", "admin")));

    private JwtAuthValidator() {}

    /**
     * Extrai o token Bearer do cabecalho Authorization, ou retorna null caso ausente.
     */
    public static String extrairBearerToken(RequisicaoHttp requisicao) {
        if (requisicao == null) return null;
        String cabecalho = requisicao.getCabecalho("authorization");
        if (cabecalho == null || cabecalho.trim().isEmpty()) return null;
        String limpo = cabecalho.trim();
        if (limpo.length() <= 7 || !limpo.regionMatches(true, 0, "Bearer ", 0, 7)) {
            throw new SecurityException("Formato do cabecalho Authorization invalido. Use Bearer <token>.");
        }
        String token = limpo.substring(7).trim();
        if (token.isEmpty()) {
            throw new SecurityException("Token Bearer ausente.");
        }
        return token;
    }

    /**
     * Valida criptograficamente um token JWT HS256 usando o segredo informado.
     */
    public static UsuarioAutenticado validarToken(String token, String segredo) {
        if (token == null || token.trim().isEmpty()) {
            throw new SecurityException("Token de autenticacao ausente.");
        }
        if (segredo == null || segredo.length() < 16) {
            throw new SecurityException("Segredo JWT nao configurado ou inseguro.");
        }

        String[] partes = token.trim().split("\\.");
        if (partes.length != 3 || partes[0].isEmpty() || partes[1].isEmpty() || partes[2].isEmpty()) {
            throw new SecurityException("Estrutura JWT malformada.");
        }

        byte[] assinaturaRecebida;
        String headerJson;
        String payloadJson;
        try {
            Base64.Decoder urlDecoder = Base64.getUrlDecoder();
            headerJson = new String(urlDecoder.decode(partes[0]), StandardCharsets.UTF_8);
            payloadJson = new String(urlDecoder.decode(partes[1]), StandardCharsets.UTF_8);
            assinaturaRecebida = urlDecoder.decode(partes[2]);
        } catch (IllegalArgumentException e) {
            throw new SecurityException("Codificacao Base64URL do token invalida.");
        }

        Map<String, Object> header;
        try {
            header = Json.analisarObjeto(headerJson);
        } catch (IllegalArgumentException e) {
            throw new SecurityException("Cabecalho JWT invalido.");
        }

        Object alg = header.get("alg");
        if (!"HS256".equals(alg)) {
            throw new SecurityException("Algoritmo JWT nao permitido.");
        }

        byte[] assinaturaEsperada = calcularHmacSha256(partes[0] + "." + partes[1], segredo);
        if (!MessageDigest.isEqual(assinaturaEsperada, assinaturaRecebida)) {
            throw new SecurityException("Assinatura do token invalida.");
        }

        Map<String, Object> claims;
        try {
            claims = Json.analisarObjeto(payloadJson);
        } catch (IllegalArgumentException e) {
            throw new SecurityException("Payload JWT invalido.");
        }

        Object subObj = claims.get("sub");
        if (!(subObj instanceof String) || ((String) subObj).trim().isEmpty()) {
            throw new SecurityException("Identificador do usuario (sub) ausente no token.");
        }

        Object profileObj = claims.get("profile");
        if (!(profileObj instanceof String)) {
            throw new SecurityException("Perfil institucional ausente no token.");
        }
        String profile = ((String) profileObj).trim().toLowerCase(Locale.ROOT);
        if (!PERFIS_VALIDOS.contains(profile)) {
            throw new SecurityException("Perfil institucional nao reconhecido: " + profile);
        }

        Object expObj = claims.get("exp");
        if (!(expObj instanceof Number)) {
            throw new SecurityException("Data de expiracao (exp) ausente no token.");
        }
        long expSegundos = ((Number) expObj).longValue();
        long agoraSegundos = System.currentTimeMillis() / 1000L;
        if (expSegundos <= agoraSegundos) {
            throw new SecurityException("Sessao expirada. Realize login novamente.");
        }

        Object nbfObj = claims.get("nbf");
        if (nbfObj instanceof Number && ((Number) nbfObj).longValue() > agoraSegundos) {
            throw new SecurityException("Token ainda nao ativo (nbf).");
        }

        String jti = claims.get("jti") instanceof String ? (String) claims.get("jti") : "";
        int ver = claims.get("ver") instanceof Number ? ((Number) claims.get("ver")).intValue() : 0;
        String identity = claims.get("identity") instanceof String ? (String) claims.get("identity") : "";
        String displayName = claims.get("name") instanceof String ? (String) claims.get("name") : "";

        return new UsuarioAutenticado(((String) subObj).trim(), profile, jti, ver, identity, displayName);
    }

    /**
     * Gera um token JWT HS256 assinado apenas com recursos nativos do JDK.
     */
    public static String gerarTokenHs256(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            long ttlSegundos,
            String segredo) {
        if (segredo == null || segredo.length() < 16) {
            throw new IllegalArgumentException("Segredo JWT deve possuir pelo menos 16 caracteres.");
        }
        long agora = System.currentTimeMillis() / 1000L;

        Map<String, Object> header = new LinkedHashMap<String, Object>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("sub", userId);
        payload.put("profile", profile);
        payload.put("ver", sessionVersion);
        if (sessionId != null && !sessionId.isEmpty()) {
            payload.put("jti", sessionId);
        }
        payload.put("iat", agora);
        payload.put("exp", agora + ttlSegundos);

        Base64.Encoder urlEncoder = Base64.getUrlEncoder().withoutPadding();
        String parteHeader = urlEncoder.encodeToString(Json.escrever(header).getBytes(StandardCharsets.UTF_8));
        String partePayload = urlEncoder.encodeToString(Json.escrever(payload).getBytes(StandardCharsets.UTF_8));
        String entradaAssinatura = parteHeader + "." + partePayload;
        String parteAssinatura = urlEncoder.encodeToString(calcularHmacSha256(entradaAssinatura, segredo));

        return entradaAssinatura + "." + parteAssinatura;
    }

    /**
     * Consulta o endpoint /api/auth/me no backend TypeScript para validar sessao ativa e nao revogada.
     */
    public static UsuarioAutenticado consultarSessaoRemota(String token) {
        if (token == null || token.trim().isEmpty()) {
            throw new SecurityException("Token ausente para verificacao remota.");
        }
        HttpURLConnection connection = null;
        try {
            String baseUrl = ConfigEnv.obter("AUTH_API_BASE_URL", "http://127.0.0.1:3001");
            while (baseUrl.endsWith("/")) {
                baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
            }
            URL url = new URL(baseUrl + "/api/auth/me");
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Authorization", "Bearer " + token.trim());
            connection.setRequestProperty("Accept", "application/json");
            connection.setConnectTimeout(TIMEOUT_REMOTO_MS);
            connection.setReadTimeout(TIMEOUT_REMOTO_MS);

            int status = connection.getResponseCode();
            if (status != HttpURLConnection.HTTP_OK) {
                throw new SecurityException("Sessao recusada ou revogada pelo servico de autenticacao.");
            }

            InputStream in = connection.getInputStream();
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] bloco = new byte[1024];
            int lido;
            while ((lido = in.read(bloco)) != -1) {
                buffer.write(bloco, 0, lido);
            }
            Map<String, Object> dados = Json.analisarObjeto(new String(buffer.toByteArray(), StandardCharsets.UTF_8));
            String id = dados.get("id") instanceof String ? (String) dados.get("id") : "";
            String profile = dados.get("profile") instanceof String ? (String) dados.get("profile") : "";
            String identity = dados.get("identity") instanceof String ? (String) dados.get("identity") : "";
            String displayName = dados.get("displayName") instanceof String ? (String) dados.get("displayName") : "";
            if (id.isEmpty() || !PERFIS_VALIDOS.contains(profile.toLowerCase(Locale.ROOT))) {
                throw new SecurityException("Resposta de sessao remota invalida.");
            }
            return new UsuarioAutenticado(id, profile, "", 0, identity, displayName);
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Nao foi possivel validar a sessao no servico de autenticacao.");
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
    }

    /**
     * Exige que a requisicao HTTP possua um token de login valido (local HS256 ou sessao remota).
     */
    public static UsuarioAutenticado autenticarObrigatorio(RequisicaoHttp requisicao) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            throw new SecurityException("Autenticacao necessaria. Informe o token Bearer do login.");
        }
        return validarComConfiguracaoAmbiente(token);
    }

    /**
     * Valida o token Bearer caso enviado na requisicao.
     * Se REQUIRE_HTTP_JWT=true estiver definido no ambiente, passa a exigir o token em todas as chamadas.
     */
    public static UsuarioAutenticado autenticarOpcional(RequisicaoHttp requisicao) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            if ("true".equalsIgnoreCase(ConfigEnv.obter("REQUIRE_HTTP_JWT", "false"))) {
                throw new SecurityException("Autenticacao necessaria.");
            }
            return null;
        }
        return validarComConfiguracaoAmbiente(token);
    }

    private static UsuarioAutenticado validarComConfiguracaoAmbiente(String token) {
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo != null && segredo.length() >= 16) {
            UsuarioAutenticado local = validarToken(token, segredo);
            if ("true".equalsIgnoreCase(ConfigEnv.obter("VERIFY_REMOTE_SESSION", "false"))) {
                return consultarSessaoRemota(token);
            }
            return local;
        }
        return consultarSessaoRemota(token);
    }

    private static byte[] calcularHmacSha256(String dados, String segredo) {
        try {
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            SecretKeySpec keySpec = new SecretKeySpec(segredo.getBytes(StandardCharsets.UTF_8), ALGORITMO_HMAC);
            mac.init(keySpec);
            return mac.doFinal(dados.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao inicializar HMAC-SHA256 no JDK: " + e.getMessage(), e);
        }
    }
}

