// Desenvolvido por Marcelo Zarpelon

package websocket;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

// Uma conexao WebSocket aberta; cada conexao e atendida por sua propria Thread.
public class ConexaoWebSocket extends Thread {
    private static final int LIMITE_MENSAGEM = 262144;
    private static final int TEMPO_OCIOSO_MS = 120000;

    private final Socket socket;
    private final InputStream entrada;
    private final OutputStream saida;
    private final OuvinteWebSocket ouvinte;
    private final String recurso;
    private volatile boolean aberta = true;

    public ConexaoWebSocket(Socket socket, String recurso, OuvinteWebSocket ouvinte) throws IOException {
        super("websocket-" + recurso);
        this.socket = socket;
        this.entrada = socket.getInputStream();
        this.saida = socket.getOutputStream();
        this.recurso = recurso;
        this.ouvinte = ouvinte;
        socket.setSoTimeout(TEMPO_OCIOSO_MS);
    }

    public String getRecurso() { return recurso; }
    public boolean isAberta() { return aberta; }

    public void enviarTexto(String texto) throws IOException {
        enviar(new QuadroWebSocket(true, QuadroWebSocket.TEXTO, texto.getBytes(StandardCharsets.UTF_8)));
    }

    // Varias threads podem enviar para a mesma conexao, por isso e sincronizado.
    private synchronized void enviar(QuadroWebSocket quadro) throws IOException {
        if (!aberta) throw new IOException("Conexao fechada");
        quadro.escrever(saida);
    }

    // Envia o quadro de fechamento com o codigo informado e encerra o socket.
    public void fechar(int codigo) {
        if (!aberta) return;
        try {
            byte[] dados = new byte[] {(byte) (codigo >> 8), (byte) (codigo & 0xFF)};
            enviar(new QuadroWebSocket(true, QuadroWebSocket.FECHAR, dados));
        } catch (IOException e) {
            // Cliente ja foi embora; o socket e fechado abaixo.
        }
        encerrar();
    }

    private synchronized void encerrar() {
        aberta = false;
        try { socket.close(); } catch (IOException e) { /* ja fechado */ }
    }

    @Override
    public void run() {
        ByteArrayOutputStream mensagem = new ByteArrayOutputStream();
        int tipoMensagem = -1;
        try {
            ouvinte.aoAbrir(this);
            while (aberta) {
                QuadroWebSocket quadro = QuadroWebSocket.ler(entrada);
                int opcode = quadro.getOpcode();
                if (opcode == QuadroWebSocket.PING) {
                    enviar(new QuadroWebSocket(true, QuadroWebSocket.PONG, quadro.getDados()));
                } else if (opcode == QuadroWebSocket.PONG) {
                    // Resposta a um ping nosso; nada a fazer.
                } else if (opcode == QuadroWebSocket.FECHAR) {
                    fechar(1000);
                    break;
                } else if (opcode == QuadroWebSocket.TEXTO || opcode == QuadroWebSocket.BINARIO) {
                    if (tipoMensagem != -1) { fechar(1002); break; }
                    tipoMensagem = opcode;
                    mensagem.reset();
                    mensagem.write(quadro.getDados());
                } else if (opcode == QuadroWebSocket.CONTINUACAO) {
                    if (tipoMensagem == -1) { fechar(1002); break; }
                    mensagem.write(quadro.getDados());
                } else {
                    fechar(1002);
                    break;
                }
                if (opcode == QuadroWebSocket.TEXTO || opcode == QuadroWebSocket.BINARIO || opcode == QuadroWebSocket.CONTINUACAO) {
                    if (mensagem.size() > LIMITE_MENSAGEM) { fechar(1009); break; }
                    if (quadro.isFim()) {
                        int tipo = tipoMensagem;
                        byte[] bytes = mensagem.toByteArray();
                        tipoMensagem = -1;
                        mensagem.reset();
                        if (tipo == QuadroWebSocket.BINARIO) { fechar(1003); break; }
                        String texto = decodificar(bytes);
                        if (texto == null) { fechar(1007); break; }
                        ouvinte.aoReceberTexto(this, texto);
                    }
                }
            }
        } catch (SocketTimeoutException e) {
            fechar(1001);
        } catch (IOException e) {
            // Conexao caiu ou cliente enviou quadro invalido.
        } finally {
            encerrar();
            ouvinte.aoFechar(this);
        }
    }

    // UTF-8 estrito: retorna null se o texto for invalido.
    private static String decodificar(byte[] bytes) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
        } catch (CharacterCodingException e) { return null; }
    }
}
