// Desenvolvido por Marcelo Zarpelon e adaptado para Java SE puro (Java 8+)

package videocall.hub;

import core.RequisicaoHttp;
import websocket.AtendenteWebSocket;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

// Teste de integracao sem bibliotecas: servidor WebSocket real e clientes em sockets crus.
public class HubTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static class Cliente {
        final Socket socket;
        final InputStream in;
        final OutputStream out;
        final String statusHandshake;

        Cliente(int porta, String caminho) throws IOException {
            socket = new Socket("127.0.0.1", porta);
            socket.setSoTimeout(1500);
            in = socket.getInputStream();
            out = socket.getOutputStream();
            String pedido = "GET " + caminho + " HTTP/1.1\r\nHost: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                    + "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";
            out.write(pedido.getBytes(StandardCharsets.US_ASCII));
            out.flush();
            ByteArrayOutputStream cab = new ByteArrayOutputStream();
            while (!new String(cab.toByteArray(), StandardCharsets.US_ASCII).endsWith("\r\n\r\n")) {
                int lido = in.read();
                if (lido < 0) break;
                cab.write(lido);
            }
            statusHandshake = new String(cab.toByteArray(), StandardCharsets.US_ASCII).split("\r\n")[0];
        }

        void enviar(String texto) throws IOException {
            byte[] d = texto.getBytes(StandardCharsets.UTF_8);
            int[] m = {9, 8, 7, 6};
            out.write(0x81);
            if (d.length < 126) out.write(0x80 | d.length);
            else {
                out.write(0x80 | 126);
                out.write(d.length >> 8);
                out.write(d.length & 0xFF);
            }
            for (int x : m) out.write(x);
            for (int i = 0; i < d.length; i++) out.write(d[i] ^ m[i % 4]);
            out.flush();
        }

        String receber() throws IOException {
            try {
                int b0 = in.read();
                if (b0 < 0) return "EOF";
                int b1 = in.read();
                int tamanho = b1 & 0x7F;
                if (tamanho == 126) tamanho = (in.read() << 8) | in.read();
                byte[] d = lerExato(in, tamanho);
                if ((b0 & 0x0F) == 0x8) return "CLOSE:" + (((d[0] & 0xFF) << 8) | (d[1] & 0xFF));
                return new String(d, StandardCharsets.UTF_8);
            } catch (SocketTimeoutException e) {
                return null;
            }
        }

        void fechar() {
            try { socket.close(); } catch (IOException ignored) {}
        }
    }

    private static byte[] lerExato(InputStream in, int tamanho) throws IOException {
        byte[] buffer = new byte[tamanho];
        int lidoTotal = 0;
        while (lidoTotal < tamanho) {
            int lido = in.read(buffer, lidoTotal, tamanho - lidoTotal);
            if (lido < 0) break;
            lidoTotal += lido;
        }
        return buffer;
    }

    static String envelope(String tipo, String sala, String remetente) {
        return "{\"protocol\":\"p2p_videocall_v1\",\"type\":\"" + tipo + "\",\"roomId\":\"" + sala
                + "\",\"senderId\":\"" + remetente + "\",\"timestamp\":1,\"payload\":{\"texto\":\"oi\"}}";
    }

    public static int executar() throws Exception {
        falhas = 0;
        final List<String> registrados = new ArrayList<String>();
        final SalaVideoHub hub = new SalaVideoHub(new RegistradorEnvelope() {
            @Override
            public void registrar(String sala, Map<String, Object> env) {
                synchronized (registrados) {
                    registrados.add(sala + ":" + env.get("type"));
                }
            }
        });
        final ServerSocket servidor = new ServerSocket(0, 50, InetAddress.getLoopbackAddress());
        int porta = servidor.getLocalPort();
        Thread aceitador = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    while (!servidor.isClosed()) {
                        Socket s = servidor.accept();
                        RequisicaoHttp req = RequisicaoHttp.ler(s.getInputStream());
                        String sala = req.getCaminho().substring(req.getCaminho().lastIndexOf('/') + 1);
                        AtendenteWebSocket.assumir(s, req, sala, hub);
                    }
                } catch (IOException ignored) {
                    // servidor encerrado
                }
            }
        });
        aceitador.setDaemon(true);
        aceitador.start();

        Cliente a = new Cliente(porta, "/ws/video-call/SALA-1");
        Cliente b = new Cliente(porta, "/ws/video-call/SALA-1");
        Cliente outraSala = new Cliente(porta, "/ws/video-call/SALA-2");
        try {
            esperar(a.statusHandshake.contains("101"), "Hub: handshake responde 101");

            a.enviar(envelope("join", "SALA-1", "peer-a"));
            String recebido = b.receber();
            esperar(recebido != null && recebido.contains("\"senderId\":\"peer-a\""), "Hub: b recebe envelope de a");
            esperar(a.receber() == null, "Hub: remetente nao recebe o proprio envelope");
            esperar(outraSala.receber() == null, "Hub: outra sala nao recebe");

            a.enviar(envelope("chat", "SALA-1", "peer-b"));
            esperar("CLOSE:1008".equals(a.receber()), "Hub: senderId diferente do primeiro fecha com 1008");

            String saida = b.receber();
            esperar(saida != null && saida.contains("\"type\":\"leave\"") && saida.contains("peer-a"), "Hub: saida de a gera leave para b");

            b.enviar(envelope("chat", "SALA-2", "peer-b"));
            esperar("CLOSE:1008".equals(b.receber()), "Hub: roomId diferente da sala fecha com 1008");

            outraSala.enviar("isto nao e json");
            esperar("CLOSE:1007".equals(outraSala.receber()), "Hub: json invalido fecha com 1007");

            synchronized (registrados) {
                esperar(registrados.contains("SALA-1:join") && registrados.contains("SALA-1:leave"), "Hub: registrador recebe join e leave");
            }
            Thread.sleep(200);
            esperar(hub.contarParticipantes("SALA-1") == 0 && hub.contarParticipantes("SALA-2") == 0, "Hub: salas esvaziam apos fechamento");
        } finally {
            a.fechar();
            b.fechar();
            outraSala.fechar();
            servidor.close();
        }
        return falhas;
    }

    public static void main(String[] args) throws Exception {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes passaram");
    }
}

