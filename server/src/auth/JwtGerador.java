// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import utils.ConfigEnv;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Gerador de tokens JWT HS256 implementado 100% na unha com a biblioteca padrao do JDK.
 * Suporta geracao de access tokens (curta duracao) e refresh tokens (longa duracao).
 *
 * Nao utiliza nenhuma dependencia externa.
 *
 * Payload inclui:
 * - sub: userId do usuario
 * - perfil: perfil institucional (aluno, docente, admin)
 * - identity: identidade normalizada do usuario
 * - name: nome de exibicao
 * - email: email do usuario
 * - jti: identificador unico do token (UUID) - usado para revogacao
 * - ver: versao da sessao (para invalidacao em massa)
 * - iat: issued at (timestamp de emissao)
 * - exp: expiration (timestamp de expiracao)
 * - type: "access" ou "refresh" (tipo do token)
 */
public final class JwtGerador {
    private static final String ALGORITMO_HMAC = "HmacSHA256";
    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    // TTLs configuraveis via .env
    private static final long TTL_ACCESS_SEGUNDOS_PADRAO = TimeUnit.MINUTES.toSeconds(15);
    private static final long TTL_REFRESH_SEGUNDOS_PADRAO = TimeUnit.DAYS.toSeconds(7);

    private JwtGerador() {}

    /**
     * Gera um access token JWT HS256 para o usuario autenticado.
     * TTL padrao: 15 minutos (configuravel via JWT_ACCESS_TOKEN_TTL_SECONDS).
     */
    public static String gerarAccessToken(UsuarioAutenticado usuario, int sessionVersion) {
        long ttl = ConfigEnv.obterInteiro("JWT_ACCESS_TOKEN_TTL_SECONDS",
                (int) TTL_ACCESS_SEGUNDOS_PADRAO);
        return gerarTokenInterno(usuario, sessionVersion, ttl, "access");
    }

    /**
     * Gera um access token com TTL customizado (para compatibilidade com codigo existente).
     * Este e o metodo original que gera tokens de 8 horas.
     */
    public static String gerarToken(UsuarioAutenticado usuario) {
        long ttl = ConfigEnv.obterInteiro("JWT_ACCESS_TOKEN_TTL_SECONDS",
                (int) TimeUnit.HOURS.toSeconds(8));
        return gerarTokenInterno(usuario, usuario.getSessionVersion(), ttl, "access");
    }

    /**
     * Gera um refresh token JWT HS256.
     * TTL padrao: 7 dias (configuravel via JWT_REFRESH_TOKEN_TTL_SECONDS).
     */
    public static String gerarRefreshToken(UsuarioAutenticado usuario, int sessionVersion) {
        long ttl = ConfigEnv.obterInteiro("JWT_REFRESH_TOKEN_TTL_SECONDS",
                (int) TTL_REFRESH_SEGUNDOS_PADRAO);
        return gerarTokenInterno(usuario, sessionVersion, ttl, "refresh");
    }

    /**
     * Gera um par de tokens (access + refresh) para o usuario autenticado.
     */
    public static ParTokens gerarParTokens(UsuarioAutenticado usuario, int sessionVersion) {
        String access = gerarAccessToken(usuario, sessionVersion);
        String refresh = gerarRefreshToken(usuario, sessionVersion);
        return new ParTokens(access, refresh);
    }

    /**
     * Extrai o JTI (JWT ID) de um token sem validar a assinatura.
     * Usado para adicionar o token a blacklist no logout.
     */
    public static String extrairJti(String token) {
        if (token == null || token.trim().isEmpty()) return null;
        String[] partes = token.trim().split("\\.");
        if (partes.length != 3) return null;

        try {
            String payloadJson = new String(
                    Base64.getUrlDecoder().decode(partes[1]),
                    StandardCharsets.UTF_8);
            // Parser simples para extrair "jti"
            String jti = utils.Json.analisarObjeto(payloadJson)
                    .get("jti") instanceof String
                    ? (String) utils.Json.analisarObjeto(payloadJson).get("jti")
                    : null;
            return jti;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Extrai a data de expiracao (exp) de um token em millis.
     */
    public static long extrairExpiracaoMillis(String token) {
        if (token == null || token.trim().isEmpty()) return 0;
        String[] partes = token.trim().split("\\.");
        if (partes.length != 3) return 0;

        try {
            String payloadJson = new String(
                    Base64.getUrlDecoder().decode(partes[1]),
                    StandardCharsets.UTF_8);
            Object expObj = utils.Json.analisarObjeto(payloadJson).get("exp");
            if (expObj instanceof Number) {
                return ((Number) expObj).longValue() * 1000L;
            }
            return 0;
        } catch (Exception e) {
            return 0;
        }
    }

    // =========================================================================
    // IMPLEMENTACAO INTERNA
    // =========================================================================

    private static String gerarTokenInterno(UsuarioAutenticado usuario, int sessionVersion,
                                             long ttlSegundos, String tipo) {
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null || segredo.length() < 16) {
            throw new IllegalStateException("Segredo JWT nao configurado ou inseguro.");
        }

        long agora = System.currentTimeMillis() / 1000;
        long expiracao = agora + ttlSegundos;
        String jti = gerarJti();

        // Header
        String headerJson = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
        String headerEncoded = URL_ENCODER.encodeToString(
                headerJson.getBytes(StandardCharsets.UTF_8));

        // Payload
        StringBuilder payload = new StringBuilder();
        payload.append("{");
        payload.append("\"sub\":\"").append(escapar(usuario.getUserId())).append("\",");
        payload.append("\"profile\":\"").append(escapar(usuario.getProfile())).append("\",");
        payload.append("\"identity\":\"").append(escapar(usuario.getIdentity())).append("\",");
        payload.append("\"name\":\"").append(escapar(usuario.getDisplayName())).append("\",");
        payload.append("\"email\":\"").append(escapar(usuario.getEmail())).append("\",");
        payload.append("\"jti\":\"").append(escapar(jti)).append("\",");
        payload.append("\"ver\":").append(sessionVersion).append(",");
        payload.append("\"iat\":").append(agora).append(",");
        payload.append("\"exp\":").append(expiracao).append(",");
        payload.append("\"type\":\"").append(escapar(tipo)).append("\"");
        payload.append("}");

        String payloadEncoded = URL_ENCODER.encodeToString(
                payload.toString().getBytes(StandardCharsets.UTF_8));

        // Assinatura
        String assinatura = assinar(headerEncoded + "." + payloadEncoded, segredo);

        return headerEncoded + "." + payloadEncoded + "." + assinatura;
    }

    /**
     * Gera um JTI (JWT ID) unico usando UUID aleatorio.
     */
    private static String gerarJti() {
        byte[] bytes = new byte[16];
        SECURE_RANDOM.nextBytes(bytes);
        return UUID.nameUUIDFromBytes(bytes).toString();
    }

    /**
     * Calcula a assinatura HMAC-SHA256.
     */
    private static String assinar(String dados, String segredo) {
        try {
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            SecretKeySpec keySpec = new SecretKeySpec(
                    segredo.getBytes(StandardCharsets.UTF_8),
                    ALGORITMO_HMAC
            );
            mac.init(keySpec);
            byte[] assinaturaBytes = mac.doFinal(dados.getBytes(StandardCharsets.UTF_8));
            return URL_ENCODER.encodeToString(assinaturaBytes);
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao calcular assinatura HMAC-SHA256: " + e.getMessage(), e);
        }
    }

    /**
     * Escapa aspas duplas em strings para JSON inline.
     */
    private static String escapar(String valor) {
        if (valor == null) return "";
        return valor.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /**
     * Par de tokens (access + refresh) retornado pelo login.
     */
    public static final class ParTokens {
        private final String accessToken;
        private final String refreshToken;

        public ParTokens(String accessToken, String refreshToken) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
        }

        public String getAccessToken() { return accessToken; }
        public String getRefreshToken() { return refreshToken; }
    }
}
