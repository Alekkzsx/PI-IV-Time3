// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.utils;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import core.RequisicaoHttp;
import core.abstratas.ExcecaoHttpAbstrata;
import utils.ConfigEnv;
import utils.Json;

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
 * Validador JWT HS256 implementado com JDK padrao + conferencia autoritativa no MongoDB.
 *
 * Validacao em duas camadas:
 * 1. Criptografica/local (validarToken): estrutura, algoritmo, assinatura, blacklist, tipo, claims e expiracao;
 * 2. Autoritativa (validarComRepositorio): sessao ativa no Mongo + sessionVersion + perfil atual + estado da conta.
 * A camada 2 e o que permite logout/revogacao/troca de senha invalidarem tokens ainda "validos" no JWT.
 */
public final class JwtAuthValidator {
    // RBAC: qualquer perfil fora desta whitelist invalida o token mesmo com assinatura correta.
    private static final Set<String> PERFIS_VALIDOS = Collections.unmodifiableSet(
            new HashSet<String>(Arrays.asList("aluno", "docente", "admin")));

    /**
     * Excecao de seguranca HTTP (401/403) integrada a hierarquia ExcecaoHttpAbstrata.
     */
    public static final class HttpSecurityException extends ExcecaoHttpAbstrata {
        public HttpSecurityException(int statusHttp, String codigo, String message) {
            super(statusHttp, codigo, message);
        }
    }

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private JwtAuthValidator() {}

    /**
     * Extrai o token do header "Authorization: Bearer <token>" (prefixo case-insensitive).
     *
     * @return token ou null se o header estiver ausente (rota pode ser publica)
     * @throws SecurityException se o header existir mas estiver malformado (vira 401)
     */
    public static String extrairBearerToken(RequisicaoHttp requisicao) {
        if (requisicao == null) {
            return null;
        }
        String cabecalho = requisicao.getCabecalho("authorization");
        if (cabecalho == null || cabecalho.trim().isEmpty()) {
            return null;
        }
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
     * Camada 1: valida o JWT localmente (sem banco) e devolve a identidade dos claims.
     * Ordem das verificacoes: estrutura -> Base64URL -> alg -> assinatura -> blacklist ->
     * tipo -> sub/profile -> exp/nbf. Qualquer falha lanca SecurityException (401).
     *
     * @param tipoEsperado "access", "refresh" ou "recovery"; null aceita qualquer tipo
     * @throws SecurityException em qualquer violacao (mensagem segura para o cliente)
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
        // Algoritmo FIXADO em HS256: rejeita "none" e RS256 (ataques de algorithm confusion).
        if (!"HS256".equals(header.get("alg"))) {
            throw new SecurityException("Algoritmo JWT nao permitido.");
        }

        byte[] assinaturaEsperada = JwtGerador.calcularHmacSha256(partes[0] + "." + partes[1], segredo);
        // MessageDigest.isEqual: comparacao em tempo constante (nao vaza prefixo valido por timing).
        if (!MessageDigest.isEqual(assinaturaEsperada, assinaturaRecebida)) {
            throw new SecurityException("Assinatura do token invalida.");
        }

        Map<String, Object> claims;
        try {
            claims = Json.analisarObjeto(payloadJson);
        } catch (IllegalArgumentException e) {
            throw new SecurityException("Payload JWT invalido.");
        }

        // Blacklist em memoria: logout imediato mesmo com JWT ainda nao expirado.
        String jti = claims.get("jti") instanceof String ? (String) claims.get("jti") : "";
        if (!jti.isEmpty() && RevogacaoTokens.getInstance().estaRevogado(jti)) {
            throw new SecurityException("Sessao encerrada. Realize login novamente.");
        }

        // Impede reuso cruzado: refresh token nao acessa rotas, access token nao renova sessao.
        String tipo = claims.get("type") instanceof String ? (String) claims.get("type") : "access";
        if (tipoEsperado != null && !tipoEsperado.equals(tipo)) {
            throw new SecurityException("Tipo de token invalido. Esperado: " + tipoEsperado + ", recebido: " + tipo);
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
        long agoraSegundos = System.currentTimeMillis() / 1000L;
        if (((Number) expObj).longValue() <= agoraSegundos) {
            throw new SecurityException("Sessao expirada. Realize login novamente.");
        }
        Object nbfObj = claims.get("nbf");
        if (nbfObj instanceof Number && ((Number) nbfObj).longValue() > agoraSegundos) {
            throw new SecurityException("Token ainda nao ativo (nbf).");
        }

        // ver default 0: tokens sem versao so passam se o banco tambem estiver em 0.
        int ver = claims.get("ver") instanceof Number ? ((Number) claims.get("ver")).intValue() : 0;
        String identity = claims.get("identity") instanceof String ? (String) claims.get("identity") : "";
        String displayName = claims.get("name") instanceof String ? (String) claims.get("name") : "";
        String email = claims.get("email") instanceof String ? (String) claims.get("email") : "";

        return new UsuarioAutenticado(
                ((String) subObj).trim(), profile, jti, ver, identity, displayName, email, false);
    }

    /** Sobrecarga sem tipo esperado (aceita access/refresh/recovery indistintamente). */
    public static UsuarioAutenticado validarToken(String token, String segredo) {
        return validarToken(token, segredo, null);
    }

    /**
     * Emissor alternativo de access token com claims minimos (usado em testes e no fluxo
     * de recovery, que precisa de jti controlado). Producao usa JwtGerador.
     */
    public static String gerarTokenHs256(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            long ttlSegundos,
            String segredo) {
        long agora = System.currentTimeMillis() / 1000L;
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("sub", userId);
        payload.put("profile", profile);
        payload.put("ver", Integer.valueOf(sessionVersion));
        payload.put("type", "access");
        if (sessionId != null && !sessionId.isEmpty()) {
            payload.put("jti", sessionId);
        }
        payload.put("iat", Long.valueOf(agora));
        payload.put("exp", Long.valueOf(agora + ttlSegundos));
        return JwtGerador.assinarClaims(payload, segredo);
    }

    /** Atalho com singleton e sem tolerancia a troca de senha pendente. */
    public static UsuarioAutenticado autenticarObrigatorio(RequisicaoHttp requisicao) {
        return autenticarObrigatorio(requisicao, RepositorioUsuarios.getInstance(), false);
    }

    /**
     * Porta de entrada das rotas autenticadas: exige Bearer + valida nas duas camadas.
     *
     * @param permitirTrocaSenhaPendente true somente na rota de troca de senha
     * @throws HttpSecurityException 401 sem token / status do resultado da sessao invalida
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

    /** Igual a autenticarObrigatorio + checagem RBAC de admin (403 se perfil inferior). */
    public static UsuarioAutenticado autenticarAdminObrigatorio(
            RequisicaoHttp requisicao,
            RepositorioUsuarios repositorio) {
        UsuarioAutenticado usuario = autenticarObrigatorio(requisicao, repositorio, false);
        if (!usuario.isAdmin()) {
            throw new HttpSecurityException(403, "forbidden", "Acesso permitido somente ao administrador.");
        }
        return usuario;
    }

    /**
     * Valida um refresh token (type=refresh) apenas na camada criptografica.
     * A sessao antiga e conferida/rotacionada pelo RefreshTokenHandler, nao aqui.
     */
    public static UsuarioAutenticado autenticarRefreshToken(RequisicaoHttp requisicao) {
        String token = extrairBearerToken(requisicao);
        if (token == null) {
            throw new HttpSecurityException(401, "authentication_required", "Refresh token necessario.");
        }
        String segredo = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        return validarToken(token, segredo, "refresh");
    }

    /** Versao com singleton tolerante: nao forca conexao Mongo se ninguem a criou ainda. */
    public static UsuarioAutenticado autenticarOpcional(RequisicaoHttp requisicao) {
        return autenticarOpcional(requisicao, RepositorioUsuarios.getInstanciaSeInicializada());
    }

    /**
     * Autenticacao tolerante (rotas legadas de videochamada): sem token devolve null,
     * exceto se REQUIRE_HTTP_JWT=true endurece a politica. Token presente SEMPRE e
     * validado por completo - nunca se aceita token invalido silenciosamente.
     */
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

    /**
     * Camada 2: apos a validacao local, consulta a sessao autoritativa no Mongo
     * (jti ativo, ver igual, perfil atual, conta ativa, troca de senha pendente).
     * O usuario devolvido e o do BANCO (dados frescos), nao o snapshot do token.
     * Repositorio ausente = 503 (fail-closed: sem banco nao se autentica ninguem).
     */
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
}
