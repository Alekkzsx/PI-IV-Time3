// Desenvolvido por Guilherme Henrique Moreira
package server;

import admin.controllers.UsuariosHandler;
import admin.repositories.UsuarioRepository;
import academico.controllers.BoletimHandler;
import academico.controllers.PresencaHandler;
import academico.controllers.TarefasHandler;
import academico.controllers.TesteTiposHandler;

import api.CrudHandler;
import database.BancoDados;
import docente.AcoesDocenteHandler;
import docente.DocenteEsquemas;
import docente.regras.SaidaNotas;
import database.BancoMemoria;
import database.BancoMongo;
import database.MongoDBConnection;
import utils.ConfigEnv;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.InetAddress;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import videocall.VideoCallEsquemas;
import videocall.hub.RegistradorChat;
import videocall.hub.SalaVideoHub;
import websocket.AtendenteWebSocket;
import websocket.HandshakeWebSocket;

// Servidor HTTP implementado com sockets nativos do Java.
public class ServidorHttpNativo {
    private static final int PORTA_PADRAO = 8080;
    private static final Map<String, ManipuladorHttp> ROTAS = new HashMap<>();
    private static final String RAIZ_WS_VIDEO = "/ws/video-call/";
    private static SalaVideoHub hubVideo = new SalaVideoHub(null);
    private static BancoDados banco;

    // Usa o MongoDB quando MONGODB_URI esta configurada; sem ela, guarda em memoria (dados perdidos ao reiniciar).
    private static BancoDados criarBanco() {
        if (ConfigEnv.obter("MONGODB_URI", null) == null) {
            System.out.println("[BANCO] MONGODB_URI ausente: usando banco em memoria");
            return new BancoMemoria();
        }
        try {
            return new BancoMongo(MongoDBConnection.conectar());
        } catch (RuntimeException e) {
            System.err.println("[BANCO] Falha ao conectar no MongoDB: " + e.getMessage());
            throw e;
        }
    }

    public static void main(String[] args) throws IOException {
        banco = criarBanco();
        UsuarioRepository usuarios = new UsuarioRepository(Path.of("data", "usuarios.db"));
        ROTAS.put("/api/admin/usuarios", new UsuariosHandler(usuarios));
        ROTAS.put("/api/teste-tipos", new TesteTiposHandler());
        ROTAS.put("/api/presenca", new PresencaHandler());
        ROTAS.put("/api/tarefas/calcular-nota", new TarefasHandler());
        ROTAS.put("/api/notas/boletim", new BoletimHandler());
        registrarRotasDocente();
        registrarRotasVideoCall();

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
                ManipuladorHttp handler = procurarRota(requisicao.getCaminho());
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

    // CRUD das colecoes do portal do docente em /api/docente/{colecao}.
    private static void registrarRotasDocente() {
        crud("/api/docente/profiles", DocenteEsquemas.DOCENTES, DocenteEsquemas.ESQUEMA_DOCENTES);
        crud("/api/docente/class-plans", DocenteEsquemas.CURSOS, DocenteEsquemas.ESQUEMA_CURSOS);
        crud("/api/docente/attendance-sessions", DocenteEsquemas.AULAS, DocenteEsquemas.ESQUEMA_AULAS);
        crud("/api/docente/assignments", DocenteEsquemas.TAREFAS, DocenteEsquemas.ESQUEMA_TAREFAS);
        ROTAS.put("/api/docente/grades", new CrudHandler("/api/docente/grades", banco.colecao(DocenteEsquemas.NOTAS),
                DocenteEsquemas.ESQUEMA_NOTAS).comSaida(SaidaNotas::calcular));
        crud("/api/docente/notices", DocenteEsquemas.AVISOS, DocenteEsquemas.ESQUEMA_AVISOS);
        crud("/api/docente/events", DocenteEsquemas.EVENTOS, DocenteEsquemas.ESQUEMA_EVENTOS);
        ROTAS.put(AcoesDocenteHandler.RAIZ, new AcoesDocenteHandler(banco));
    }

    // CRUD das colecoes da video chamada em /api/video-call/{colecao}; o chat do hub e gravado no banco.
    private static void registrarRotasVideoCall() {
        crud("/api/video-call/rooms", VideoCallEsquemas.SALAS, VideoCallEsquemas.ESQUEMA_SALAS);
        crud("/api/video-call/sessions", VideoCallEsquemas.SESSOES, VideoCallEsquemas.ESQUEMA_SESSOES);
        crud("/api/video-call/chat-messages", VideoCallEsquemas.MENSAGENS, VideoCallEsquemas.ESQUEMA_MENSAGENS);
        hubVideo = new SalaVideoHub(new RegistradorChat(banco.colecao(VideoCallEsquemas.MENSAGENS)));
    }

    private static void crud(String rota, String colecao, api.Esquema esquema) {
        ROTAS.put(rota, new CrudHandler(rota, banco.colecao(colecao), esquema));
    }

    // Uma rota atende o proprio caminho e tudo abaixo dele (ex.: /api/admin/usuarios/{id}).
    private static ManipuladorHttp procurarRota(String caminho) {
        ManipuladorHttp handler = ROTAS.get(caminho);
        if (handler != null) return handler;
        String melhor = null;
        for (String rota : ROTAS.keySet()) {
            if (caminho.startsWith(rota + "/") && (melhor == null || rota.length() > melhor.length())) melhor = rota;
        }
        return melhor == null ? null : ROTAS.get(melhor);
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
