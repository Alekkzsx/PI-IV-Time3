// Desenvolvido por Guilherme Henrique Moreira
// Atualizado com headers de seguranca defensivos
package core;

import utils.ConfigEnv;
import utils.Json;

import java.io.IOException;
import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Map;

// Metodos utilitarios compartilhados pelo servidor HTTP nativo.
public final class HttpUtils {
    private HttpUtils() { }

    public static void aplicarHeadersCors(RespostaHttp resposta) {
        String originPermitido = ConfigEnv.obter("ALLOWED_ORIGINS", "*");
        resposta.adicionarCabecalho("Access-Control-Allow-Origin", originPermitido);
        resposta.adicionarCabecalho("Access-Control-Allow-Methods",
                ConfigEnv.obter("CORS_ALLOWED_METHODS", "GET, POST, PUT, PATCH, DELETE, OPTIONS"));
        resposta.adicionarCabecalho("Access-Control-Allow-Headers",
                ConfigEnv.obter("CORS_ALLOWED_HEADERS", "Content-Type, Authorization, X-Requested-With"));
        String maxAge = ConfigEnv.obter("CORS_MAX_AGE_SECONDS", "86400");
        resposta.adicionarCabecalho("Access-Control-Max-Age", maxAge);
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

    public static String lerCorpoRequisicao(RequisicaoHttp requisicao) {
        return requisicao.getCorpo();
    }

    /**
     * Extrai parametros do corpo HTTP aceitando tanto JSON plano quanto x-www-form-urlencoded.
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

    public static void enviarResposta(RespostaHttp resposta, int status, String conteudo) throws IOException {
        resposta.enviar(status, conteudo);
    }
}
