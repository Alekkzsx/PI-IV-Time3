// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import videocall.modules.hub.RegistradorChat;
import videocall.modules.hub.SalaVideoHub;
import videocall.modules.legado.VideoCallService;
import videocall.modules.rooms.TicketWebSocketValidator;
import websocket.AtendenteWebSocket;
import websocket.HandshakeWebSocket;

// Servidor HTTP multithreaded nativo sem dependencias externas de framework.
/**
 * Servidor HTTP/1.1 + WebSocket construido sobre ServerSocket/Socket puros (sem framework).
 *
 * Modelo de concorrencia: pool fixo de 32 threads; a thread principal fica no loop de
 * accept() e cada conexao e atendida por uma worker. Requisicoes HTTP comuns morrem na
 * propria worker (Connection: close); upgrades WebSocket transferem a posse do socket
 * para a thread dedicada de ConexaoWebSocket.
 *
 * Roteamento: match exato primeiro; depois prefixo mais longo ("/api/admin/users/123"
 * cai no handler de "/api/admin/users"). O mapa so e escrito no boot (antes do accept),
 * por isso nao precisa de sincronizacao em runtime.
 */
public class ServidorHttpNativo {
    // Prefixo das URLs de upgrade WebSocket: /ws/video-call/{codigoDaSala}?ticket=...
    private static final String RAIZ_WS_VIDEO = "/ws/video-call/";
    // Hub unico de sinalizacao compartilhado por todas as salas/conexoes WebSocket do processo.
    private static final SalaVideoHub HUB_VIDEO =
            new SalaVideoHub(new RegistradorChat(VideoCallService.getInstance()));

    private final int porta;
    private final Map<String, ManipuladorHttp> rotas = new LinkedHashMap<String, ManipuladorHttp>();
    private ServerSocket serverSocket;
    private ExecutorService threadPool;
    // volatile: parar() pode ser chamado de outra thread (shutdown) e o loop de accept precisa enxergar.
    private volatile boolean rodando = false;

    public ServidorHttpNativo(int porta) {
        this.porta = porta;
    }

    /** Registra (ou substitui) o handler de um caminho exato; chamado apenas durante o boot. */
    public void registrarRota(String caminho, ManipuladorHttp manipulador) {
        rotas.put(caminho, manipulador);
    }

    /** @return visao somente leitura da tabela de rotas (diagnostico/testes). */
    public Map<String, ManipuladorHttp> getRotas() {
        return Collections.unmodifiableMap(rotas);
    }

    /** @return hub singleton de videochamada, usado tambem pelos handlers HTTP legados. */
    public static SalaVideoHub getHubVideo() {
        return HUB_VIDEO;
    }

    /**
     * Abre o ServerSocket e entra no loop de accept (bloqueia a thread chamadora).
     * Cada conexao aceita e despachada para o pool; falhas individuais de accept nao
     * derrubam o servidor, apenas sao logadas.
     *
     * @throws IOException se o bind da porta falhar (porta ocupada, permissao...)
     */
    public void iniciar() throws IOException {
        // 32 workers: folga para HTTP curto + conexoes WS longas sem esgotar o pool em uso academico.
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

    /** Encerra o loop de accept, fecha o ServerSocket e desliga o pool (usado em testes/shutdown). */
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

    /**
     * Atende uma conexao do inicio ao fim na thread worker:
     * parse -> CORS -> (upgrade WS | preflight OPTIONS | rota HTTP) -> close.
     *
     * socketAssumido controla a posse do socket: se o upgrade WebSocket deu certo,
     * ConexaoWebSocket passa a ser dona do socket e o finally NAO pode fecha-lo.
     */
    private void atender(Socket cliente) {
        boolean socketAssumido = false;
        try {
            // 30s de read timeout: derruba clientes lentos/maliciosos (slowloris) antes de prender a worker.
            cliente.setSoTimeout(30000);
            RespostaHttp resposta = new RespostaHttp(cliente.getOutputStream());
            try {
                RequisicaoHttp requisicao = RequisicaoHttp.ler(cliente.getInputStream());
                HttpUtils.aplicarHeadersCors(requisicao, resposta);

                // Upgrade tem prioridade sobre o roteamento HTTP: a conexao deixa de ser request/response.
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
                // Falha de parse/protocolo vira 400; aspas da mensagem sao trocadas para nao quebrar o JSON.
                if (!resposta.foiEnviada()) {
                    resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Requisicao invalida: " + e.getMessage().replace("\"", "'") + "\"}");
                }
            } catch (Exception e) {
                // Rede de seguranca final: erro inesperado vira 500 generico (sem vazar detalhes internos).
                System.err.println("[ERRO CRITICO] " + e.getMessage());
                if (!resposta.foiEnviada()) {
                    resposta.enviarJson(500, "{\"status\":500,\"erro\":\"Erro interno no servidor.\"}");
                }
            } finally {
                // So fecha quem ainda e dono do socket; conexao WS ativa pertence a ConexaoWebSocket.
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

    /**
     * Resolve o handler: match exato primeiro; se nao houver, escolhe o prefixo registrado
     * MAIS LONGO que casa com "rota/..." (ex.: /api/admin/users/abc -> /api/admin/users).
     * O '/' exigido apos o prefixo evita que /api/auth/logout-others case com /api/auth/logout.
     */
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

    /**
     * Valida e executa o upgrade WebSocket em 4 portoes, todos fail-closed:
     * caminho sob /ws/video-call/ -> formato do codigo da sala -> handshake RFC 6455 ->
     * ticket de uso unico emitido pelo enter da sala. So entao entrega o socket ao hub.
     *
     * @return true se o socket foi assumido pela conexao WebSocket (nao fechar no finally)
     */
    private boolean abrirWebSocket(Socket cliente, RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        String caminho = requisicao.getCaminho();
        if (!caminho.startsWith(RAIZ_WS_VIDEO)) {
            resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Endpoint WebSocket nao encontrado.\"}");
            return false;
        }

        String sala = caminho.substring(RAIZ_WS_VIDEO.length());
        // Whitelist do codigo da sala: sem barras/espacos/unicode, maximo 60 chars (anti path traversal/log injection).
        if (!sala.matches("[a-zA-Z0-9._-]{1,60}")) {
            resposta.enviarJson(404, "{\"status\":404,\"erro\":\"Sala invalida.\"}");
            return false;
        }

        try {
            HandshakeWebSocket.validar(requisicao);
        } catch (IllegalArgumentException e) {
            resposta.enviarJson(400, "{\"status\":400,\"erro\":\"Handshake WebSocket invalido.\"}");
            return false;
        }

        // Ticket vindo do POST /api/video-call/enter: consumo atomico de uso unico impede replay/corrida.
        Map<String, String> parametros = HttpUtils.parseFormUrlEncoded(requisicao.getQueryParams());
        String ticket = parametros.get("ticket");
        if (!TicketWebSocketValidator.consume(ticket, sala)) {
            resposta.enviarJson(401, "{\"status\":401,\"erro\":\"Autorizacao da sala ausente ou expirada.\"}");
            return false;
        }

        // WS e conexao longa e ociosa por natureza: remove o read timeout de 30s do HTTP.
        cliente.setSoTimeout(0);
        return AtendenteWebSocket.assumir(cliente, requisicao, sala, HUB_VIDEO);
    }
}
