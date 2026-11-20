// Desenvolvido por Murillo Caravita - RA: 25014012
package auth.utils;

import auth.model.UsuarioAutenticado;
import utils.ConfigEnv;
import utils.Json;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Emissor unificado de tokens JWT HS256 (access, refresh e recovery) em Java SE puro.
 * Centraliza a assinatura HMAC-SHA256 e a leitura de claims (jti, exp) sem duplicacao.
 */
public final class JwtGerador {
    private static final String ALGORITMO_HMAC = "HmacSHA256";
    // Base64URL SEM padding '=': formato exigido pelo JWT/JWS (RFC 7515) para caber em URLs/headers.
    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    // TTLs padrao: access curto (15min, limita janela de roubo), refresh longo (7 dias), recovery 15min.
    private static final long TTL_ACCESS_SEGUNDOS_PADRAO = TimeUnit.MINUTES.toSeconds(15);
    private static final long TTL_REFRESH_SEGUNDOS_PADRAO = TimeUnit.DAYS.toSeconds(7);
    private static final long TTL_RECOVERY_SEGUNDOS = TimeUnit.MINUTES.toSeconds(15);

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private JwtGerador() {}

    /** Access token padrao do login (TTL configuravel por JWT_ACCESS_TOKEN_TTL_SECONDS, default 15min). */
    public static String gerarAccessToken(UsuarioAutenticado usuario, int sessionVersion) {
        long ttl = ConfigEnv.obterInteiro("JWT_ACCESS_TOKEN_TTL_SECONDS", (int) TTL_ACCESS_SEGUNDOS_PADRAO);
        return gerarTokenInterno(usuario, sessionVersion, ttl, "access");
    }

    /** Variante legada sem sessionVersion explicita (default de 8h quando o .env nao define TTL). */
    public static String gerarToken(UsuarioAutenticado usuario) {
        long ttl = ConfigEnv.obterInteiro("JWT_ACCESS_TOKEN_TTL_SECONDS", (int) TimeUnit.HOURS.toSeconds(8));
        return gerarTokenInterno(usuario, usuario.getSessionVersion(), ttl, "access");
    }

    /** Refresh token (type=refresh): so serve para renovar o par em /api/auth/refresh, nunca para acessar rotas. */
    public static String gerarRefreshToken(UsuarioAutenticado usuario, int sessionVersion) {
        long ttl = ConfigEnv.obterInteiro("JWT_REFRESH_TOKEN_TTL_SECONDS", (int) TTL_REFRESH_SEGUNDOS_PADRAO);
        return gerarTokenInterno(usuario, sessionVersion, ttl, "refresh");
    }

    /**
     * Gera token JWT temporario de recuperacao de senha (TTL 15 minutos, tipo "recovery").
     * O uso unico nao e garantido pelo JWT e sim pelo fluxo de reset (fingerprint consumido no Mongo).
     */
    public static String gerarRecoveryToken(UsuarioAutenticado usuario) {
        return gerarTokenInterno(usuario, usuario.getSessionVersion(), TTL_RECOVERY_SEGUNDOS, "recovery");
    }

    /** Emite o par access+refresh com a mesma sessionVersion (usado por login/2FA/refresh/reset). */
    public static ParTokens gerarParTokens(UsuarioAutenticado usuario, int sessionVersion) {
        return new ParTokens(
                gerarAccessToken(usuario, sessionVersion),
                gerarRefreshToken(usuario, sessionVersion)
        );
    }

    /**
     * Assina qualquer conjunto de claims em um JWT HS256 usando o segredo fornecido.
     * Formato final: base64url(header) + "." + base64url(payload) + "." + base64url(HMAC).
     *
     * @throws IllegalArgumentException se o segredo tiver menos de 16 caracteres (fail-fast contra segredo fraco)
     */
    public static String assinarClaims(Map<String, Object> payload, String segredo) {
        if (segredo == null || segredo.length() < 16) {
            throw new IllegalArgumentException("Segredo JWT deve possuir pelo menos 16 caracteres.");
        }
        Map<String, Object> header = new LinkedHashMap<String, Object>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        String headerEncoded = URL_ENCODER.encodeToString(Json.escrever(header).getBytes(StandardCharsets.UTF_8));
        String payloadEncoded = URL_ENCODER.encodeToString(Json.escrever(payload).getBytes(StandardCharsets.UTF_8));
        String entrada = headerEncoded + "." + payloadEncoded;
        String assinatura = URL_ENCODER.encodeToString(calcularHmacSha256(entrada, segredo));
        return entrada + "." + assinatura;
    }

    /** HMAC-SHA256 cru compartilhado entre emissor (aqui) e validador (JwtAuthValidator). */
    public static byte[] calcularHmacSha256(String dados, String segredo) {
        try {
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            SecretKeySpec keySpec = new SecretKeySpec(segredo.getBytes(StandardCharsets.UTF_8), ALGORITMO_HMAC);
            mac.init(keySpec);
            return mac.doFinal(dados.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Falha ao calcular assinatura HMAC-SHA256: " + e.getMessage(), e);
        }
    }

    /**
     * Le o claim jti SEM validar assinatura - seguro apenas para tokens que ACABAMOS de emitir
     * (ex.: registrar a sessao). Nunca usar para decisao de autorizacao.
     */
    public static String extrairJti(String token) {
        Map<String, Object> claims = decodificarPayloadSemValidar(token);
        if (claims == null) {
            return null;
        }
        Object jti = claims.get("jti");
        return jti instanceof String ? (String) jti : null;
    }

    /** Le o exp (segundos) e converte para epoch millis; 0 se ausente/invalido. Sem validar assinatura. */
    public static long extrairExpiracaoMillis(String token) {
        Map<String, Object> claims = decodificarPayloadSemValidar(token);
        if (claims == null) {
            return 0L;
        }
        Object expObj = claims.get("exp");
        return expObj instanceof Number ? ((Number) expObj).longValue() * 1000L : 0L;
    }

    /** Decode Base64URL do payload sem nenhuma verificacao criptografica (uso interno pos-emissao). */
    private static Map<String, Object> decodificarPayloadSemValidar(String token) {
        if (token == null || token.trim().isEmpty()) {
            return null;
        }
        String[] partes = token.trim().split("\\.");
        if (partes.length != 3) {
            return null;
        }
        try {
            String payloadJson = new String(Base64.getUrlDecoder().decode(partes[1]), StandardCharsets.UTF_8);
            return Json.analisarObjeto(payloadJson);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Monta o conjunto de claims padrao e assina. Claims-chave:
     * jti (id unico da sessao), ver (versao de sessao - troca de senha invalida tokens antigos),
     * type (access|refresh|recovery - impede reuso cruzado) e iat/exp em segundos (padrao JWT).
     */
    private static String gerarTokenInterno(
            UsuarioAutenticado usuario,
            int sessionVersion,
            long ttlSegundos,
            String tipo) {
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null || segredo.length() < 16) {
            throw new IllegalStateException("Segredo JWT nao configurado ou inseguro.");
        }
        long agora = System.currentTimeMillis() / 1000L;
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("sub", usuario.getUserId());
        payload.put("profile", usuario.getProfile());
        payload.put("identity", usuario.getIdentity());
        payload.put("name", usuario.getDisplayName());
        payload.put("email", usuario.getEmail());
        payload.put("jti", gerarJti());
        payload.put("ver", Integer.valueOf(sessionVersion));
        payload.put("iat", Long.valueOf(agora));
        payload.put("exp", Long.valueOf(agora + ttlSegundos));
        payload.put("type", tipo);
        return assinarClaims(payload, segredo);
    }

    /** jti aleatorio: 16 bytes do SecureRandom formatados como UUID (128 bits de entropia). */
    private static String gerarJti() {
        byte[] bytes = new byte[16];
        SECURE_RANDOM.nextBytes(bytes);
        return UUID.nameUUIDFromBytes(bytes).toString();
    }

    /** DTO imutavel do par de tokens emitido no login. */
    public static final class ParTokens {
        private final String accessToken;
        private final String refreshToken;

        public ParTokens(String accessToken, String refreshToken) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
        }

        /** @return token curto de acesso as rotas (type=access). */
        public String getAccessToken() { return accessToken; }
        /** @return token longo de renovacao (type=refresh). */
        public String getRefreshToken() { return refreshToken; }
    }
}
