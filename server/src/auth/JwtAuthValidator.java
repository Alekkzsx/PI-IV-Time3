// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.RequisicaoHttp;
import utils.ConfigEnv;
import utils.Json;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
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
 * Validador JWT HS256 implementado com a biblioteca padrao do JDK + conferencia autoritativa no MongoDB.
 */
public final class JwtAuthValidator {
    private static final String ALGORITMO_HMAC = "HmacSHA256";
    private static final Set<String> PERFIS_VALIDOS = Collections.unmodifiableSet(
            new HashSet<String>(Arrays.asList("aluno", "docente", "admin")));

    /**
     * Excecao de seguranca com status HTTP e codigo semantico (401/403).
     */
    public static final class HttpSecurityException extends SecurityException {
        private final int statusHttp;
        private final String codigo;

        public HttpSecurityException(int statusHttp, String codigo, String message) {
            super(message);
            this.statusHttp = statusHttp;
            this.codigo = codigo;
        }

        public int getStatusHttp() { return statusHttp; }
        public String getCodigo() { return codigo; }
    }

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
     * Verifica tambem a blacklist de tokens revogados.
     *
     * @param token          Token JWT a ser validado.
     * @param segredo        Segredo HMAC-SHA256.
     * @param tipoEsperado   Tipo de token esperado ("access" ou "refresh"), ou null para qualquer tipo.
     * @return UsuarioAutenticado com os claims extraidos.
     * @throws SecurityException se o token for invalido, expirado ou revogado.
     */
    public static UsuarioAutenticado validarToken(String token, String segredo, String tipoEsperado) {
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

        // Verificar blacklist (token revogado via logout)
        Object jtiObj = claims.get("jti");
        String jti = jtiObj instanceof String ? (String) jtiObj : "";
        if (!jti.isEmpty() && RevogacaoTokens.getInstance().estaRevogado(jti)) {
            throw new SecurityException("Sessao encerrada. Realize login novamente.");
        }

        // Verificar tipo do token
        Object typeObj = claims.get("type");
        String tipo = typeObj instanceof String ? (String) typeObj : "access";
        if (tipoEsperado != null && !tipoEsperado.equals(tipo)) {
            throw new SecurityException("Tipo de token invalido. Esperado: " + tipoEsperado + ", recebido: " + tipo);
        }

        // Verificar claims obrigatorios
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

        int ver = claims.get("ver") instanceof Number ? ((Number) claims.get("ver")).intValue() : 0;
        String identity = claims.get("identity") instanceof String ? (String) claims.get("identity") : "";
        String displayName = claims.get("name") instanceof String ? (String) claims.get("name") : "";
        String email = claims.get("email") instanceof String ? (String) claims.get("email") : "";

        return new UsuarioAutenticado(
                ((String) subObj).trim(),
                profile,
                jti,
                ver,
                identity,
                displayName,
                email,
                false
        );
    }

    /**
     * Valida um token JWT (compatibilidade com assinatura anterior).
     */
    public static UsuarioAutenticado validarToken(String token, String segredo) {
        return validarToken(token, segredo, null);
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
        payload.put("type", "access");
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
     * Exige que a requisicao HTTP possua um access token valido no MongoDB (sessao ativa, versao e conta).
     */
    public static UsuarioAutenticado autenticarObrigatorio(RequisicaoHttp requisicao) {
        return autenticarObrigatorio(requisicao, RepositorioUsuarios.getInstance(), false);
    }

    /**
     * Exige access token valido permitindo opcionalmente rotas de troca obrigatoria de senha (/me, /logout, /change-password).
     */
    public static UsuarioAutenticado autenticarObrigatorio(
            RequisicaoHttp requisicao,
            RepositorioUsuarios repositorio,
            boolean permitirTrocaSenhaPendente) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            throw new HttpSecurityException(401, "authentication_required",
                    "Autenticacao necessaria. Informe o token Bearer do login.");
        }
        return validarComRepositorio(token, "access", repositorio, permitirTrocaSenhaPendente);
    }

    /**
     * Exige sessao administrativa valida (perfil "admin", sessao ativa no MongoDB e senha regularizada).
     */
    public static UsuarioAutenticado autenticarAdminObrigatorio(
            RequisicaoHttp requisicao,
            RepositorioUsuarios repositorio) {
        UsuarioAutenticado usuario = autenticarObrigatorio(requisicao, repositorio, false);
        if (!usuario.isAdmin()) {
            throw new HttpSecurityException(403, "forbidden",
                    "Acesso permitido somente ao administrador.");
        }
        return usuario;
    }

    /**
     * Exige um refresh token valido na requisicao.
     */
    public static UsuarioAutenticado autenticarRefreshToken(RequisicaoHttp requisicao) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            throw new HttpSecurityException(401, "authentication_required", "Refresh token necessario.");
        }
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        return validarToken(token, segredo, "refresh");
    }

    /**
     * Valida o token Bearer caso enviado na requisicao.
     * Se REQUIRE_HTTP_JWT=true estiver definido no ambiente, passa a exigir o token em todas as chamadas.
     */
    public static UsuarioAutenticado autenticarOpcional(RequisicaoHttp requisicao) {
        return autenticarOpcional(requisicao, RepositorioUsuarios.getInstanciaSeInicializada());
    }

    public static UsuarioAutenticado autenticarOpcional(RequisicaoHttp requisicao, RepositorioUsuarios repositorio) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            if ("true".equalsIgnoreCase(ConfigEnv.obter("REQUIRE_HTTP_JWT", "false"))) {
                throw new HttpSecurityException(401, "authentication_required", "Autenticacao necessaria.");
            }
            return null;
        }
        return validarComRepositorio(token, "access", repositorio, false);
    }

    private static UsuarioAutenticado validarComRepositorio(
            String token,
            String tipoEsperado,
            RepositorioUsuarios repositorio,
            boolean permitirTrocaSenhaPendente) {
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (segredo == null || segredo.length() < 16) {
            throw new HttpSecurityException(500, "jwt_config_error", "Segredo JWT nao configurado.");
        }
        UsuarioAutenticado local = validarToken(token, segredo, tipoEsperado);
        if (repositorio == null) {
            throw new HttpSecurityException(503, "auth_store_unavailable",
                    "Repositorio de sessoes indisponivel para validar token.");
        }
        RepositorioUsuarios.ResultadoValidacaoSessao res = repositorio.validarSessaoCompleta(
                local.getUserId(),
                local.getSessionId(),
                local.getSessionVersion(),
                local.getProfile(),
                permitirTrocaSenhaPendente
        );
        if (!res.valida) {
            throw new HttpSecurityException(res.statusHttp, res.codigo, res.mensagem);
        }
        return res.usuario;
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
