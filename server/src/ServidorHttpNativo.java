// Desenvolvido por Guilherme Henrique Moreira

import com.sun.net.httpserver.HttpServer;

import java.net.InetSocketAddress;

/**
 * Ponto de entrada e configuração do servidor HTTP nativo da plataforma AGMRM.
 */
public class ServidorHttpNativo {

    private static final int PORTA_PADRAO = 8080;

    public static void main(String[] args) throws Exception {
        int porta = PORTA_PADRAO;

        HttpServer server = HttpServer.create(new InetSocketAddress(porta), 0);

        server.createContext("/api/teste-tipos", new TesteTiposHandler());
        server.createContext("/api/presenca", new PresencaHandler());
        server.createContext("/api/tarefas/calcular-nota", new TarefasHandler());
        server.createContext("/api/notas/boletim", new BoletimHandler());

        server.setExecutor(null);
        server.start();

        System.out.println("==================================================");
        System.out.println("   SERVIDOR HTTP NATIVO INICIADO COM SUCESSO!     ");
        System.out.println("   Escutando na porta: " + porta);
        System.out.println("==================================================");
        System.out.println("Endpoints disponiveis:");
        System.out.println(" -> POST http://localhost:" + porta + "/api/teste-tipos");
        System.out.println(" -> POST http://localhost:" + porta + "/api/presenca");
        System.out.println(" -> POST http://localhost:" + porta + "/api/tarefas/calcular-nota");
        System.out.println(" -> POST http://localhost:" + porta + "/api/notas/boletim");
        System.out.println("==================================================\n");
    }
}