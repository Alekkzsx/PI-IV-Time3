// Desenvolvido por Guilherme Henrique Moreira

import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

// Métodos auxiliares para os endpoints existentes.
public final class HttpUtils {
    private HttpUtils() { }

    public static void aplicarHeadersCors(RespostaHttp resposta) {
        resposta.adicionarCabecalho("Access-Control-Allow-Origin", "*");
        resposta.adicionarCabecalho("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        resposta.adicionarCabecalho("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    public static String lerCorpoRequisicao(RequisicaoHttp requisicao) {
        return requisicao.getCorpo();
    }

    // Converte os campos enviados por formulário em chave e valor.
    public static Map<String, String> parseFormUrlEncoded(String corpo) {
        Map<String, String> dados = new HashMap<>();
        if (corpo == null || corpo.isBlank()) return dados;
        for (String item : corpo.split("&")) {
            String[] partes = item.split("=", 2);
            try {
                dados.put(URLDecoder.decode(partes[0], StandardCharsets.UTF_8),
                        URLDecoder.decode(partes.length == 2 ? partes[1] : "", StandardCharsets.UTF_8));
            } catch (IllegalArgumentException e) {
                // Mantém a entrada caso a codificação tenha caracteres inválidos.
                dados.put(partes[0], partes.length == 2 ? partes[1] : "");
            }
        }
        return dados;
    }

    public static void enviarResposta(RespostaHttp resposta, int status, String conteudo) throws IOException {
        resposta.enviar(status, conteudo);
    }
}
