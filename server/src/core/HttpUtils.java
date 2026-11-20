// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
// Atualizado com headers de seguranca defensivos
package core;

import utils.ConfigEnv;
import utils.Json;
import utils.RedeUtils;

import java.io.IOException;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

// Metodos utilitarios compartilhados pelo servidor HTTP nativo.
/**
 * Utilitarios HTTP compartilhados: CORS dinamico (com Private Network Access),
 * headers de seguranca defensivos, parse de parametros (JSON ou form-urlencoded)
 * e resposta de erro padronizada. Tudo configuravel pelo .env mestre.
 */
public final class HttpUtils {
    // Origens de desenvolvimento sempre aceitas fora de producao: localhost/127.0.0.1/[::1] com qualquer porta.
    private static final Pattern LOOPBACK_ORIGIN_PATTERN = Pattern.compile(
            "^https?://(localhost|127\\.0\\.0\\.1|\\[::1\\])(:\\d{1,5})?$",
            Pattern.CASE_INSENSITIVE
    );
    // Faixas privadas RFC 1918 (10/8, 192.168/16, 172.16-31): liberadas apenas com ALLOW_LAN_CORS=true.
    private static final Pattern LAN_ORIGIN_PATTERN = Pattern.compile(
            "^https?://(10\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}|192\\.168\\.\\d{1,3}\\.\\d{1,3}|172\\.(1[6-9]|2\\d|3[0-1])\\.\\d{1,3}\\.\\d{1,3})(:\\d{1,5})?$",
            Pattern.CASE_INSENSITIVE
    );

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private HttpUtils() { }

    /** Sobrecarga sem requisicao (sem Origin): aplica CORS padrao + defaults de metodos/headers. */
    public static void aplicarHeadersCors(RespostaHttp resposta) {
        aplicarHeadersCors(null, resposta);
    }

    /**
     * Aplica os cabecalhos CORS na resposta conforme a Origin da requisicao.
     * Emite sempre uma unica origem (nunca lista multi-valorada, que navegadores rejeitam)
     * e adiciona Vary: Origin para caches nao misturarem respostas de origens diferentes.
     */
    public static void aplicarHeadersCors(RequisicaoHttp requisicao, RespostaHttp resposta) {
        String originHeader = requisicao != null ? requisicao.getCabecalho("origin") : null;
        String originPermitido = resolverOriginCors(originHeader);
        if (originPermitido != null && !originPermitido.isEmpty()) {
            resposta.adicionarCabecalho("Access-Control-Allow-Origin", originPermitido);
            if (!"*".equals(originPermitido)) {
                resposta.adicionarCabecalho("Vary", "Origin");
            }
        }
        resposta.adicionarCabecalho("Access-Control-Allow-Methods",
                ConfigEnv.obter("CORS_ALLOWED_METHODS", "GET, POST, PUT, PATCH, DELETE, OPTIONS"));
        resposta.adicionarCabecalho("Access-Control-Allow-Headers",
                ConfigEnv.obter("CORS_ALLOWED_HEADERS", "Content-Type, Authorization, X-Requested-With, Accept, Origin"));
        // Private Network Access (Chrome): pagina publica acessando localhost precisa deste
        // header no preflight, senao o navegador bloqueia a chamada ao servidor local.
        if (requisicao != null
                && "true".equalsIgnoreCase(requisicao.getCabecalho("access-control-request-private-network"))
                && originPermitido != null && !originPermitido.isEmpty()) {
            resposta.adicionarCabecalho("Access-Control-Allow-Private-Network", "true");
        }
        String maxAge = ConfigEnv.obter("CORS_MAX_AGE_SECONDS", "86400");
        resposta.adicionarCabecalho("Access-Control-Max-Age", maxAge);
    }

    /**
     * Resolve uma unica origem valida para Access-Control-Allow-Origin, evitando cabecalhos multi-valorados.
     * Le a whitelist do .env com fallback em cadeia: ALLOWED_ORIGINS > CORS_ORIGIN > ALLOWED_ORIGIN > "*".
     */
    public static String resolverOriginCors(String originHeader) {
        String configured = ConfigEnv.obter("ALLOWED_ORIGINS", null);
        if (configured == null || configured.isEmpty()) {
            configured = ConfigEnv.obter("CORS_ORIGIN", null);
        }
        if (configured == null || configured.isEmpty()) {
            configured = ConfigEnv.obter("ALLOWED_ORIGIN", "*");
        }
        boolean production = "production".equalsIgnoreCase(ConfigEnv.obter("NODE_ENV", "development"));
        boolean allowLan = "true".equalsIgnoreCase(ConfigEnv.obter("ALLOW_LAN_CORS", "false"));
        return resolverOriginCors(originHeader, configured, production, allowLan);
    }

    /**
     * Versao pura (sem .env) da resolucao de origem, exposta para testes unitarios.
     * Ordem: wildcard configurado -> "*"; match exato na whitelist (case-insensitive);
     * fora de producao aceita loopback e, se allowLan, faixas RFC 1918; senao null (bloqueia).
     *
     * @param originHeader      valor do header Origin da requisicao (pode ser null)
     * @param configuredOrigins lista separada por virgula de ALLOWED_ORIGINS
     * @param production        true quando NODE_ENV=production (desliga afrouxamentos de dev)
     * @param allowLan          libera origens de rede local privada
     * @return origem unica a ecoar em Access-Control-Allow-Origin, "*" ou null para negar
     */
    public static String resolverOriginCors(String originHeader, String configuredOrigins, boolean production, boolean allowLan) {
        List<String> allowed = new ArrayList<String>();
        boolean hasWildcard = false;
        if (configuredOrigins != null) {
            for (String item : configuredOrigins.split(",")) {
                String clean = removerBarraFinal(item);
                if (clean.isEmpty()) continue;
                if ("*".equals(clean)) {
                    hasWildcard = true;
                } else {
                    allowed.add(clean);
                }
            }
        }
        if (hasWildcard) {
            return "*";
        }
        if (originHeader == null || originHeader.trim().isEmpty()) {
            return null;
        }
        String cleanOrigin = removerBarraFinal(originHeader);
        for (String item : allowed) {
            if (item.equalsIgnoreCase(cleanOrigin)) {
                return cleanOrigin;
            }
        }
        if (!production) {
            if (LOOPBACK_ORIGIN_PATTERN.matcher(cleanOrigin).matches()) {
                return cleanOrigin;
            }
            if (allowLan && LAN_ORIGIN_PATTERN.matcher(cleanOrigin).matches()) {
                return cleanOrigin;
            }
        }
        return null;
    }

    /** Normaliza origem removendo barras finais para comparacao consistente. */
    private static String removerBarraFinal(String value) {
        return RedeUtils.limparBarraFinal(value);
    }

    /**
     * Aplica headers de seguranca defensivos (configuraveis via .env).
     * - X-Content-Type-Options: nosniff
     * - X-Frame-Options: DENY
     * - X-XSS-Protection: 1; mode=block
     * - Strict-Transport-Security (HSTS)
     * - Content-Security-Policy
     * - Cache-Control: no-store (para endpoints de auth)
     */
    public static void aplicarHeadersSeguranca(RespostaHttp resposta) {
        resposta.adicionarCabecalho("X-Content-Type-Options",
                ConfigEnv.obter("HEADER_X_CONTENT_TYPE_OPTIONS", "nosniff"));
        resposta.adicionarCabecalho("X-Frame-Options",
                ConfigEnv.obter("HEADER_X_FRAME_OPTIONS", "DENY"));
        resposta.adicionarCabecalho("X-XSS-Protection",
                ConfigEnv.obter("HEADER_X_XSS_PROTECTION", "1; mode=block"));
        resposta.adicionarCabecalho("Strict-Transport-Security",
                ConfigEnv.obter("HEADER_STRICT_TRANSPORT_SECURITY", "max-age=31536000; includeSubDomains"));
        resposta.adicionarCabecalho("Content-Security-Policy",
                ConfigEnv.obter("HEADER_CONTENT_SECURITY_POLICY",
                        "default-src 'self'; script-src 'self'; object-src 'none'"));
        resposta.adicionarCabecalho("Referrer-Policy", "strict-origin-when-cross-origin");
    }

    /**
     * Aplica headers especificos para endpoints de autenticacao.
     * Inclui Cache-Control: no-store para evitar cache de tokens.
     */
    public static void aplicarHeadersAuth(RespostaHttp resposta) {
        aplicarHeadersSeguranca(resposta);
        resposta.adicionarCabecalho("Cache-Control", "no-store, no-cache, must-revalidate");
        resposta.adicionarCabecalho("Pragma", "no-cache");
        resposta.adicionarCabecalho("Expires", "0");
    }

    /** @return corpo bruto da requisicao (acucar sintatico sobre getCorpo). */
    public static String lerCorpoRequisicao(RequisicaoHttp requisicao) {
        return requisicao.getCorpo();
    }

    /**
     * Extrai parametros do corpo HTTP aceitando tanto JSON plano quanto x-www-form-urlencoded.
     * Heuristica: corpo comecando com '{' tenta JSON primeiro; se o parse falhar, cai no
     * parser de formulario. Valores nao-string do JSON sao convertidos via String.valueOf.
     */
    public static Map<String, String> extrairParametros(RequisicaoHttp requisicao) {
        String corpo = requisicao.getCorpo();
        if (corpo == null || corpo.trim().isEmpty()) {
            return new HashMap<String, String>();
        }
        String limpo = corpo.trim();
        if (limpo.startsWith("{")) {
            try {
                Map<String, Object> objeto = Json.analisarObjeto(limpo);
                Map<String, String> resultado = new HashMap<String, String>();
                for (Map.Entry<String, Object> campo : objeto.entrySet()) {
                    if (campo.getValue() != null) {
                        resultado.put(campo.getKey(), String.valueOf(campo.getValue()));
                    }
                }
                return resultado;
            } catch (IllegalArgumentException ignored) {
                // Fallback para parser form-urlencoded caso nao seja JSON valido
            }
        }
        return parseFormUrlEncoded(corpo);
    }

    // Converte parametros de x-www-form-urlencoded ou query string para Map.
    /**
     * Parseia "a=1&b=2" decodificando URL-encoding UTF-8 de chaves e valores.
     * Par malformado nao derruba o parse: entra cru no mapa (o handler decide rejeitar).
     */
    public static Map<String, String> parseFormUrlEncoded(String corpoOuQuery) {
        Map<String, String> dados = new HashMap<String, String>();
        if (corpoOuQuery == null || corpoOuQuery.trim().isEmpty()) return dados;
        for (String item : corpoOuQuery.split("&")) {
            if (item.trim().isEmpty()) continue;
            String[] partes = item.split("=", 2);
            try {
                String chave = URLDecoder.decode(partes[0], "UTF-8");
                String valor = partes.length == 2 ? URLDecoder.decode(partes[1], "UTF-8") : "";
                dados.put(chave, valor);
            } catch (Exception e) {
                dados.put(partes[0], partes.length == 2 ? partes[1] : "");
            }
        }
        return dados;
    }

    // Extrator de campos simples de JSON sem dependencias externas de biblioteca.
    /**
     * Extrai um campo de nivel raiz por busca textual (sem parse completo).
     * Barato para ler 1-2 campos de payloads grandes; NAO valida JSON nem lida com
     * campos aninhados/escapes complexos - para isso use Json.analisarObjeto.
     *
     * @return valor textual do campo, ou null se ausente/malformado
     */
    public static String extrairCampoJson(String json, String campo) {
        if (json == null || json.trim().isEmpty() || campo == null) return null;
        String alvo = "\"" + campo + "\"";
        int idx = json.indexOf(alvo);
        if (idx == -1) return null;
        int doisPontos = json.indexOf(':', idx + alvo.length());
        if (doisPontos == -1) return null;

        int inicio = doisPontos + 1;
        while (inicio < json.length() && Character.isWhitespace(json.charAt(inicio))) {
            inicio++;
        }
        if (inicio >= json.length()) return null;

        char delimitador = json.charAt(inicio);
        if (delimitador == '"') {
            int fim = json.indexOf('"', inicio + 1);
            if (fim != -1) {
                return json.substring(inicio + 1, fim);
            }
        } else {
            int fim = inicio;
            while (fim < json.length() && json.charAt(fim) != ',' && json.charAt(fim) != '}' && json.charAt(fim) != ']' && !Character.isWhitespace(json.charAt(fim))) {
                fim++;
            }
            return json.substring(inicio, fim).trim();
        }
        return null;
    }

    /** Encaminha direto para RespostaHttp.enviar (compatibilidade de chamadas antigas). */
    public static void enviarResposta(RespostaHttp resposta, int status, String conteudo) throws IOException {
        resposta.enviar(status, conteudo);
    }

    /**
     * Resposta de erro no envelope padrao {status, code, message, erro}.
     * O campo duplicado message/erro existe por compatibilidade: clientes antigos leem
     * 'erro' (pt-BR) e o frontend atual le 'message'.
     */
    public static void enviarErroJson(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        Map<String, Object> erro = new java.util.LinkedHashMap<String, Object>();
        erro.put("status", Integer.valueOf(status));
        erro.put("code", codigo != null ? codigo : "error");
        erro.put("message", mensagem != null ? mensagem : "Erro interno.");
        erro.put("erro", mensagem != null ? mensagem : "Erro interno.");
        resposta.enviarJson(status, Json.escrever(erro));
    }
}
