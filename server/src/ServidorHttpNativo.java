// Desenvolvido por Guilherme Henrique Moreira

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// Servidor HTTP implementado com sockets nativos do Java.
public class ServidorHttpNativo {
    private static final int PORTA_PADRAO = 8080;
    private static final Map<String, ManipuladorHttp> ROTAS = new HashMap<>();

    public static void main(String[] args) throws IOException {
        ROTAS.put("/api/teste-tipos", new TesteTiposHandler());
        ROTAS.put("/api/presenca", new PresencaHandler());
        ROTAS.put("/api/tarefas/calcular-nota", new TarefasHandler());
        ROTAS.put("/api/notas/boletim", new BoletimHandler());

        ExecutorService trabalhadores = Executors.newFixedThreadPool(16);
        try (ServerSocket servidor = new ServerSocket(PORTA_PADRAO)) {
            System.out.println("SERVIDOR HTTP NATIVO INICIADO NA PORTA " + PORTA_PADRAO);
            for (String rota : ROTAS.keySet()) System.out.println(" -> POST http://localhost:" + PORTA_PADRAO + rota);
            while (true) {
                Socket cliente = servidor.accept();
                trabalhadores.execute(() -> atender(cliente));
            }
        } finally {
            trabalhadores.shutdown();
        }
    }

    // Cada conexão é atendida por uma thread do conjunto de trabalhadores.
    private static void atender(Socket cliente) {
        try (Socket conexao = cliente) {
            conexao.setSoTimeout(30000);
            RespostaHttp resposta = new RespostaHttp(conexao.getOutputStream());
            try {
                RequisicaoHttp requisicao = RequisicaoHttp.ler(conexao.getInputStream());
                HttpUtils.aplicarHeadersCors(resposta);
                ManipuladorHttp handler = ROTAS.get(requisicao.getCaminho());
                if (handler == null) {
                    resposta.enviar(404, "Endpoint nao encontrado.");
                } else {
                    handler.handle(requisicao, resposta);
                }
            } catch (IOException e) {
                if (!resposta.foiEnviada()) resposta.enviar(400, "Requisicao invalida: " + e.getMessage());
            } catch (Exception e) {
                System.err.println("[ERRO] " + e.getMessage());
                if (!resposta.foiEnviada()) resposta.enviar(500, "Erro interno do servidor.");
            }
        } catch (IOException e) {
            System.err.println("[CONEXAO] " + e.getMessage());
        }
    }
}
