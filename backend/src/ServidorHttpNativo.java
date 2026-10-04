// Desenvolvido por Guilherme Henrique Moreira
// Classes necessárias para criar o servidor HTTP nativo
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class ServidorHttpNativo {

    // Método principal: inicia e configura o servidor
    public static void main(String[] args) throws Exception {
        // Define a porta que será utilizada pelo servidor
        int porta = 8080;

        // Cria o servidor HTTP na porta 8080
        HttpServer server = HttpServer.create(new InetSocketAddress(porta), 0);

        // Registra os endpoints e define qual Handler irá processá-los
        server.createContext("/api/teste-tipos", new TesteTiposHandler());
        server.createContext("/api/presenca", new PresencaHandler());
        server.createContext("/api/tarefas/calcular-nota", new TarefasHandler());
        server.createContext("/api/notas/boletim", new BoletimHandler());

        // Utiliza o executor padrão do servidor
        server.setExecutor(null);

        // Inicia o servidor
        server.start();

        // Exibe informações no terminal
        System.out.println("==================================================");
        System.out.println("   SERVIDOR HTTP NATIVO INICIADO COM SUCESSO!     ");
        System.out.println("   Escutando na porta: " + porta);
        System.out.println("==================================================");
        System.out.println("Endpoints disponiveis:");
        System.out.println(" -> POST http://localhost:8080/api/teste-tipos");
        System.out.println(" -> POST http://localhost:8080/api/presenca");
        System.out.println(" -> POST http://localhost:8080/api/tarefas/calcular-nota");
        System.out.println(" -> POST http://localhost:8080/api/notas/boletim");
        System.out.println("==================================================\n");
    }

    // ============================================================
    // MÉTODOS AUXILIARES
    // ============================================================

    // Configura os headers CORS para permitir comunicação com o frontend
    private static void aplicarHeadersCors(HttpExchange exchange) {
        exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    // Lê o conteúdo enviado no corpo da requisição HTTP
    private static String lerCorpoRequisicao(HttpExchange exchange) throws IOException {
        InputStream is = exchange.getRequestBody();
        BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
        StringBuilder bodyBuilder = new StringBuilder();

        String linha;
        while ((linha = reader.readLine()) != null) {
            bodyBuilder.append(linha);
        }

        return bodyBuilder.toString();
    }

    // Converte "chave=valor&chave=valor" em um Map
    // Exemplo: nome=Joao&idade=20 -> nome=Joao, idade=20
    private static Map<String, String> parseFormUrlEncoded(String body) {
        Map<String, String> mapa = new HashMap<>();

        if (body == null || body.trim().isEmpty()) return mapa;

        // Divide os parâmetros pelo "&"
        String[] parametros = body.split("&");

        for (String param : parametros) {
            // Divide cada parâmetro entre chave e valor pelo "="
            String[] chaveValor = param.split("=");

            if (chaveValor.length == 2) {
                mapa.put(chaveValor[0], chaveValor[1]);
            } else if (chaveValor.length == 1) {
                mapa.put(chaveValor[0], "");
            }
        }

        return mapa;
    }

    // Envia uma resposta HTTP para o cliente
    private static void enviarResposta(HttpExchange exchange, int statusCode, String resposta) throws IOException {
        byte[] bytes = resposta.getBytes(StandardCharsets.UTF_8);

        // Envia o código HTTP e o tamanho da resposta
        exchange.sendResponseHeaders(statusCode, bytes.length);

        // Escreve o conteúdo da resposta e fecha o fluxo
        OutputStream os = exchange.getResponseBody();
        os.write(bytes);
        os.close();
    }

    // ============================================================
    // HANDLER: TESTE DE CONVERSÃO DE TIPOS
    // ============================================================

    // Processa as requisições feitas para /api/teste-tipos
    static class TesteTiposHandler implements HttpHandler {

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            aplicarHeadersCors(exchange);

            // Trata a requisição OPTIONS utilizada pelo CORS
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                enviarResposta(exchange, 204, "");
                return;
            }

            // Este endpoint aceita somente POST
            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = lerCorpoRequisicao(exchange);

                System.out.println("\n[LOG] POST /api/teste-tipos - Corpo bruto: " + body);

                Map<String, String> params = parseFormUrlEncoded(body);

                try {
                    // Obtém os valores enviados e converte para seus respectivos tipos
                    String textoFinal = params.getOrDefault("texto", "vazio");
                    int inteiroFinal = Integer.parseInt(params.getOrDefault("inteiro", "0"));
                    float flutuanteFinal = Float.parseFloat(params.getOrDefault("flutuante", "0.0"));
                    double duploFinal = Double.parseDouble(params.getOrDefault("duplo", "0.0"));

                    // char recebe apenas um caractere; por isso usamos charAt(0)
                    String strChar = params.getOrDefault("caractere", "X");
                    char caractereFinal = strChar.length() > 0 ? strChar.charAt(0) : 'X';

                    // Exibe os valores convertidos no terminal
                    System.out.println("--- Conversao de Tipos com Sucesso ---");
                    System.out.println("String  (texto)     : " + textoFinal);
                    System.out.println("int     (inteiro)   : " + inteiroFinal);
                    System.out.println("float   (flutuante) : " + flutuanteFinal);
                    System.out.println("double  (duplo)     : " + duploFinal);
                    System.out.println("char    (caractere) : " + caractereFinal);
                    System.out.println("---------------------------------------");

                    // Monta a resposta que será enviada ao cliente
                    String resposta = "OK - Tipos Processados: [" + textoFinal + ", "
                            + inteiroFinal + ", " + flutuanteFinal + ", "
                            + duploFinal + ", " + caractereFinal + "]";

                    enviarResposta(exchange, 200, resposta);

                } catch (Exception e) {
                    // Caso alguma conversão falhe, retorna erro 400
                    System.err.println("[ERRO] Erro na conversao: " + e.getMessage());
                    enviarResposta(exchange, 400, "Erro de Conversao: " + e.getMessage());
                }

            } else {
                // Método diferente de POST não é permitido
                enviarResposta(exchange, 405, "Metodo nao permitido. Use POST.");
            }
        }
    }

    // ============================================================
    // HANDLER: CÁLCULO DE PRESENÇA
    // ============================================================

    // Processa as requisições feitas para /api/presenca
    static class PresencaHandler implements HttpHandler {

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            aplicarHeadersCors(exchange);

            // Trata a requisição OPTIONS do CORS
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                enviarResposta(exchange, 204, "");
                return;
            }

            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = lerCorpoRequisicao(exchange);
                Map<String, String> params = parseFormUrlEncoded(body);

                try {
                    // Obtém os minutos assistidos e a duração total da aula
                    int minutosAssistidos = Integer.parseInt(
                        params.getOrDefault("minutosAssistidos", "0")
                    );
                    int duracaoTotal = Integer.parseInt(
                        params.getOrDefault("duracaoTotal", "60")
                    );

                    // Permite que o professor informe manualmente o status
                    String statusManual = params.get("statusManual");
                    String resultado;

                    if (statusManual != null && !statusManual.trim().isEmpty()) {
                        // Se houver ajuste manual, ele tem prioridade
                        resultado = statusManual.toUpperCase() + " (Ajuste Manual do Professor)";
                    } else {
                        // Calcula o percentual de presença
                        double percentual = ((double) minutosAssistidos / duracaoTotal) * 100;

                        // Define o status de acordo com o percentual
                        if (percentual >= 75.0) {
                            resultado = "PRESENCA_INTEGRAL (" + Math.round(percentual) + "%)";
                        } else if (percentual >= 50.0) {
                            resultado = "MEIA_PRESENCA (" + Math.round(percentual) + "%)";
                        } else {
                            resultado = "FALTA_AUTOMATICA (" + Math.round(percentual) + "%)";
                        }
                    }

                    System.out.println("[LOG] Calculo de Presenca: " + resultado);

                    enviarResposta(exchange, 200, "Resultado Presenca: " + resultado);

                } catch (Exception e) {
                    // Erro nos dados enviados
                    enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
                }

            } else {
                enviarResposta(exchange, 405, "Use POST.");
            }
        }
    }

    // ============================================================
    // HANDLER: CÁLCULO DA NOTA DA TAREFA
    // ============================================================

    // Processa as requisições feitas para /api/tarefas/calcular-nota
    static class TarefasHandler implements HttpHandler {

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            aplicarHeadersCors(exchange);

            // Trata a requisição OPTIONS do CORS
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                enviarResposta(exchange, 204, "");
                return;
            }

            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = lerCorpoRequisicao(exchange);
                Map<String, String> params = parseFormUrlEncoded(body);

                try {
                    // Obtém os dias de atraso e a nota original
                    int diasAtraso = Integer.parseInt(
                        params.getOrDefault("diasAtraso", "0")
                    );
                    double notaBase = Double.parseDouble(
                        params.getOrDefault("notaBase", "10.0")
                    );

                    // Inicialmente, a nota máxima é a nota original
                    double notaMaximaPermitida = notaBase;

                    if (diasAtraso > 0) {
                        // Cada dia de atraso gera um desconto de 20%
                        double desconto = diasAtraso * 0.20;

                        // Aplica o desconto
                        notaMaximaPermitida = notaBase * (1.0 - desconto);

                        // Impede que a nota fique negativa
                        if (notaMaximaPermitida < 0) {
                            notaMaximaPermitida = 0.0;
                        }
                    }

                    System.out.println(
                        "[LOG] Tarefa entregue com " + diasAtraso
                        + " dia(s) de atraso. Nota Maxima: "
                        + notaMaximaPermitida
                    );

                    enviarResposta(
                        exchange,
                        200,
                        "Nota Maxima Permitida: " + notaMaximaPermitida
                    );

                } catch (Exception e) {
                    // Erro nos dados enviados
                    enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
                }

            } else {
                enviarResposta(exchange, 405, "Use POST.");
            }
        }
    }

    // ============================================================
    // HANDLER: CÁLCULO DO BOLETIM
    // ============================================================

    // Processa as requisições feitas para /api/notas/boletim
    static class BoletimHandler implements HttpHandler {

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            aplicarHeadersCors(exchange);

            // Trata a requisição OPTIONS do CORS
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                enviarResposta(exchange, 204, "");
                return;
            }

            if ("POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                String body = lerCorpoRequisicao(exchange);
                Map<String, String> params = parseFormUrlEncoded(body);

                try {
                    // Obtém as notas e seus respectivos pesos
                    double n1 = Double.parseDouble(params.getOrDefault("p1", "0.0"));
                    double w1 = Double.parseDouble(params.getOrDefault("peso1", "0.4"));

                    double n2 = Double.parseDouble(params.getOrDefault("p2", "0.0"));
                    double w2 = Double.parseDouble(params.getOrDefault("peso2", "0.4"));

                    double n3 = Double.parseDouble(params.getOrDefault("trabalho", "0.0"));
                    double w3 = Double.parseDouble(
                        params.getOrDefault("pesoTrabalho", "0.2")
                    );

                    // Calcula a soma das notas multiplicadas pelos pesos
                    double somaNotasPesos = (n1 * w1) + (n2 * w2) + (n3 * w3);

                    // Soma os pesos utilizados
                    double somaPesos = w1 + w2 + w3;

                    // Calcula a média ponderada
                    double media = somaPesos > 0
                        ? (somaNotasPesos / somaPesos)
                        : 0.0;

                    // Arredonda a média para duas casas decimais
                    media = Math.round(media * 100.0) / 100.0;

                    String status;

                    // Define o status final do aluno
                    if (media >= 7.0) {
                        status = "APROVADO";
                    } else if (media >= 5.0) {
                        status = "EM_RECUPERACAO";
                    } else {
                        status = "REPROVADO_POR_NOTA";
                    }

                    System.out.println(
                        "[LOG] Calculo Boletim -> Media: "
                        + media + " | Status: " + status
                    );

                    // Envia a média e o status para o cliente
                    enviarResposta(
                        exchange,
                        200,
                        "Media Final: " + media + " | Status: " + status
                    );

                } catch (Exception e) {
                    // Erro nos dados enviados
                    enviarResposta(exchange, 400, "Dados invalidos: " + e.getMessage());
                }

            } else {
                enviarResposta(exchange, 405, "Use POST.");
            }
        }
    }
}