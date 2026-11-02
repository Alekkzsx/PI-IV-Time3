// Desenvolvido por Guilherme Henrique Moreira
package server;

import admin.controllers.UsuariosHandler;
import admin.repositories.UsuarioRepository;
import academico.controllers.BoletimHandler;
import academico.controllers.PresencaHandler;
import academico.controllers.TarefasHandler;
import academico.controllers.TesteTiposHandler;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.InetAddress;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import videocall.hub.SalaVideoHub;
import websocket.AtendenteWebSocket;
import websocket.HandshakeWebSocket;

// Servidor HTTP implementado com sockets nativos do Java.
public class ServidorHttpNativo {
    private static final int PORTA_PADRAO = 8080;
    private static final Map<String, ManipuladorHttp> ROTAS = new HashMap<>();
    private static final String RAIZ_WS_VIDEO = "/ws/video-call/";
    private static SalaVideoHub hubVideo = new SalaVideoHub(null);

    public static void main(String[] args) throws IOException {
        UsuarioRepository usuarios = new UsuarioRepository(Path.of("data", "usuarios.db"));
        ROTAS.put("/api/admin/usuarios", new UsuariosHandler(usuarios));
        ROTAS.put("/api/teste-tipos", new TesteTiposHandler());
        ROTAS.put("/api/presenca", new PresencaHandler());
        ROTAS.put("/api/tarefas/calcular-nota", new TarefasHandler());
        ROTAS.put("/api/notas/boletim", new BoletimHandler());

        int porta = Integer.parseInt(System.getenv().getOrDefault("SERVER_PORT", "8080"));
        ExecutorService trabalhadores = Executors.newFixedThreadPool(16);
        try (ServerSocket servidor = new ServerSocket(porta, 50, InetAddress.getLoopbackAddress())) {
            System.out.println("SERVIDOR HTTP NATIVO INICIADO NA PORTA " + porta);
            for (String rota : ROTAS.keySet()) System.out.println(" -> http://localhost:" + porta + rota);
            System.out.println(" -> ws://localhost:" + porta + RAIZ_WS_VIDEO + "{sala}");
            while (true) {
                Socket cliente = servidor.accept();
                trabalhadores.execute(() -> atender(cliente));
            }
        } finally {
            trabalhadores.shutdown();
        }
    }

    // Cada conexão é atendida por uma thread do conjunto de trabalhadores.
    // Conexoes WebSocket passam a ser donas do socket e ele nao e fechado aqui.
    private static void atender(Socket conexao) {
        boolean assumida = false;
        try {
            conexao.setSoTimeout(30000);
            RespostaHttp resposta = new RespostaHttp(conexao.getOutputStream());
            try {
                RequisicaoHttp requisicao = RequisicaoHttp.ler(conexao.getInputStream());
                HttpUtils.aplicarHeadersCors(resposta);
                if (HandshakeWebSocket.pedeUpgrade(requisicao)) {
                    assumida = abrirWebSocket(conexao, requisicao, resposta);
                    return;
                }
                ManipuladorHttp handler = ROTAS.get(requisicao.getCaminho());
                if (handler == null && requisicao.getCaminho().startsWith("/api/admin/usuarios/")) {
                    handler = ROTAS.get("/api/admin/usuarios");
                }
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
        } finally {
            if (!assumida) {
                try { conexao.close(); } catch (IOException e) { /* ja fechado */ }
            }
        }
    }

    // Rota /ws/video-call/{sala}: o identificador da sala segue as mesmas regras de ID da API.
    private static boolean abrirWebSocket(Socket conexao, RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        String caminho = requisicao.getCaminho();
        String sala = caminho.startsWith(RAIZ_WS_VIDEO) ? caminho.substring(RAIZ_WS_VIDEO.length()) : "";
        if (!sala.matches("[a-zA-Z0-9._-]{1,60}")) {
            resposta.enviar(404, "Endpoint WebSocket nao encontrado.");
            return false;
        }
        conexao.setSoTimeout(0);
        return AtendenteWebSocket.assumir(conexao, requisicao, sala, hubVideo);
    }
}
