// Desenvolvido por Guilherme Henrique Moreira
package core;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import videocall.TicketWebSocketValidator;
import videocall.VideoCallService;
import videocall.hub.RegistradorChat;
import videocall.hub.SalaVideoHub;
import websocket.AtendenteWebSocket;
import websocket.HandshakeWebSocket;

// Servidor HTTP multithreaded nativo sem dependencias externas de framework.
public class ServidorHttpNativo {
    private static final String RAIZ_WS_VIDEO = "/ws/video-call/";
    private static final SalaVideoHub HUB_VIDEO =
            new SalaVideoHub(new RegistradorChat(VideoCallService.getInstance()));

    private final int porta;
    private final Map<String, ManipuladorHttp> rotas = new LinkedHashMap<String, ManipuladorHttp>();
    private ServerSocket serverSocket;
    private ExecutorService threadPool;
    private volatile boolean rodando = false;

    public ServidorHttpNativo(int porta) {
        this.porta = porta;
    }

    public void registrarRota(String caminho, ManipuladorHttp manipulador) {
        rotas.put(caminho, manipulador);
    }

    public Map<String, ManipuladorHttp> getRotas() {
        return Collections.unmodifiableMap(rotas);
    }

    public void iniciar() throws IOException {
        threadPool = Executors.newFixedThreadPool(32);
        serverSocket = new ServerSocket(porta);
        rodando = true;

        System.out.println("====================================================================");
        System.out.println(" SERVIDOR AGMRM INICIADO NA PORTA: " + porta);
        System.out.println(" Threads no Pool: 32 | Arquitetura: Java Nativo Sockets");
        System.out.println(" Rotas Registradas (" + rotas.size() + "):");
        for (String rota : rotas.keySet()) {
            System.out.println("   -> http://localhost:" + porta + rota);
        }
        System.out.println("   -> ws://localhost:" + porta + RAIZ_WS_VIDEO + "{sala}");
        System.out.println("====================================================================");

        while (rodando) {
            try {
                final Socket cliente = serverSocket.accept();
                threadPool.execute(new Runnable() {
                    @Override
                    public void run() {
                        atender(cliente);
                    }
                });
            } catch (IOException e) {
                if (!rodando) break;
                System.err.println("[AVISO] Falha ao aceitar conexao: " + e.getMessage());
            }
        }
    }

    public void parar() {
        rodando = false;
        try {
            if (serverSocket != null && !serverSocket.isClosed()) {
                serverSocket.close();
            }
        } catch (IOException ignored) { }
        if (threadPool != null) {
            threadPool.shutdown();
        }
    }

    private void atender(Socket cliente) {
        boolean socketAssumido = false;
        try {
            cliente.setSoTimeout(30000);
            RespostaHttp resposta = new RespostaHttp(cliente.getOutputStream());
            try {
                RequisicaoHttp requisicao = RequisicaoHttp.ler(cliente.getInputStream());
                HttpUtils.aplicarHeadersCors(resposta);

                if (HandshakeWebSocket.pedeUpgrade(requisicao)) {
                    socketAssumido = abrirWebSocket(cliente, requisicao, resposta);
                    return;
                }

                if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
                    resposta.enviar(204, "");
                    return;
                }

                ManipuladorHttp handler = procurarRota(requisicao.getCaminho());
                if (handler == null) {
                    resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Endpoint nao encontrado: " + requisicao.getCaminho() + "\"}");
                } else {
                    handler.handle(requisicao, resposta);
                }
            } catch (IOException e) {
                if (!resposta.foiEnviada()) {
                    resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Requisicao invalida: " + e.getMessage().replace("\"", "'") + "\"}");
                }
            } catch (Exception e) {
                System.err.println("[ERRO CRITICO] " + e.getMessage());
                if (!resposta.foiEnviada()) {
                    resposta.enviarJson(500, "{\"status\":500,\"erro\":\"Erro interno no servidor.\"}");
                }
            } finally {
                if (!socketAssumido) {
                    try {
                        cliente.close();
                    } catch (IOException ignored) { }
                }
            }
        } catch (IOException e) {
            System.err.println("[SOCKET CONEXAO] " + e.getMessage());
        }
    }

    private ManipuladorHttp procurarRota(String caminho) {
        ManipuladorHttp handler = rotas.get(caminho);
        if (handler != null) return handler;
        String melhor = null;
        for (String rota : rotas.keySet()) {
            if (caminho.startsWith(rota + "/") && (melhor == null || rota.length() > melhor.length())) {
                melhor = rota;
            }
        }
        return melhor == null ? null : rotas.get(melhor);
    }

    private boolean abrirWebSocket(Socket cliente, RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        String caminho = requisicao.getCaminho();
        if (!caminho.startsWith(RAIZ_WS_VIDEO)) {
            resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Endpoint WebSocket nao encontrado.\"}");
            return false;
        }

        String sala = caminho.substring(RAIZ_WS_VIDEO.length());
        if (!sala.matches("[a-zA-Z0-9._-]{1,60}")) {
            resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Sala invalida.\"}");
            return false;
        }

        try {
            HandshakeWebSocket.validar(requisicao);
        } catch (IllegalArgumentException e) {
            return AtendenteWebSocket.assumir(cliente, requisicao, sala, HUB_VIDEO);
        }

        Map<String, String> parametros = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
        String ticket = parametros.get("ticket");
        if (!TicketWebSocketValidator.consume(ticket, sala)) {
            resposta.enviarJson(401, "{\"status\":401,\"erro\":\"Autorizacao da sala ausente ou expirada.\"}");
            return false;
        }

        cliente.setSoTimeout(0);
        return AtendenteWebSocket.assumir(cliente, requisicao, sala, HUB_VIDEO);
    }
}
