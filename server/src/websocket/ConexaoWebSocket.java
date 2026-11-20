// Desenvolvido por Marcelo Zarpelon - RA: 25015323

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
/**
 * Uma conexao WebSocket aberta; cada conexao e atendida por sua propria Thread.
 *
 * Responsabilidades: loop de leitura de quadros, remontagem de mensagens fragmentadas
 * (TEXTO/BINARIO + CONTINUACAO), resposta automatica a PING, encerramento com os codigos
 * da RFC 6455 (1000 normal, 1001 ocioso, 1002 protocolo, 1003 dado nao aceito,
 * 1007 UTF-8 invalido, 1009 mensagem grande) e notificacao do OuvinteWebSocket.
 *
 * Concorrencia: a thread leitora e quem chama os callbacks; envios podem vir de outras
 * threads (broadcast do hub), por isso escrever no socket e synchronized.
 */
public class ConexaoWebSocket extends Thread {
    // Teto da mensagem REMONTADA (soma dos fragmentos): 256 KB, independente do limite por quadro.
    private static final int LIMITE_MENSAGEM = 262144;
    // Sem trafego por 120s (nem ping do cliente) -> fecha com 1001; read timeout do socket.
    private static final int TEMPO_OCIOSO_MS = 120000;

    private final Socket socket;
    private final InputStream entrada;
    private final OutputStream saida;
    private final OuvinteWebSocket ouvinte;
    private final String recurso;
    // volatile: fechar() pode ser chamado pelo hub em outra thread enquanto run() le.
    private volatile boolean aberta = true;

    /**
     * Assume o socket ja com handshake 101 enviado (ver AtendenteWebSocket).
     *
     * @param recurso identificador do recurso (codigo da sala) - vira o nome da thread
     * @param ouvinte callbacks de abertura/mensagem/fechamento (ex.: SalaVideoHub)
     */
    public ConexaoWebSocket(Socket socket, String recurso, OuvinteWebSocket ouvinte) throws IOException {
        super("websocket-" + recurso);
        this.socket = socket;
        this.entrada = socket.getInputStream();
        this.saida = socket.getOutputStream();
        this.recurso = recurso;
        this.ouvinte = ouvinte;
        socket.setSoTimeout(TEMPO_OCIOSO_MS);
    }

    /** @return recurso (sala) ao qual esta conexao pertence. */
    public String getRecurso() { return recurso; }
    /** @return true enquanto o socket nao foi encerrado. */
    public boolean isAberta() { return aberta; }

    /** Envia uma mensagem de texto completa (UTF-8, quadro unico com FIN=1). */
    public void enviarTexto(String texto) throws IOException {
        enviar(new QuadroWebSocket(true, QuadroWebSocket.TEXTO, texto.getBytes(StandardCharsets.UTF_8)));
    }

    // synchronized: broadcast (outra thread) e pong/close (thread leitora) nao podem intercalar frames no mesmo socket.
    private synchronized void enviar(QuadroWebSocket quadro) throws IOException {
        if (!aberta) throw new IOException("Conexao fechada");
        quadro.escrever(saida);
    }

    /**
     * Fecha a conexao educadamente: envia quadro FECHAR com o codigo de status em
     * 2 bytes big-endian (RFC 6455 5.5.1) e encerra o socket. Best-effort: se o cliente
     * ja caiu, o envio falha silenciosamente e o socket e fechado do mesmo jeito.
     */
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

    /** Encerramento idempotente do socket (pode ser chamado por fechar() e pelo finally do run()). */
    private synchronized void encerrar() {
        aberta = false;
        try { socket.close(); } catch (IOException e) { /* ja fechado */ }
    }

    /**
     * Loop principal da conexao: le quadros, trata controle (PING/PONG/FECHAR) e
     * remonta mensagens fragmentadas ate o FIN antes de entregar ao ouvinte.
     * tipoMensagem = -1 significa "nenhuma mensagem em andamento" (estado da remontagem).
     */
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
                    // PONG deve ecoar exatamente o payload do PING (RFC 5.5.3).
                    enviar(new QuadroWebSocket(true, QuadroWebSocket.PONG, quadro.getDados()));
                } else if (opcode == QuadroWebSocket.PONG) {
                    // Resposta a um ping nosso; nada a fazer.
                } else if (opcode == QuadroWebSocket.FECHAR) {
                    fechar(1000); // encerramento normal pedido pelo cliente
                    break;
                } else if (opcode == QuadroWebSocket.TEXTO || opcode == QuadroWebSocket.BINARIO) {
                    // Novo frame de dados no meio de mensagem fragmentada = erro de protocolo (1002).
                    if (tipoMensagem != -1) { fechar(1002); break; }
                    tipoMensagem = opcode;
                    mensagem.reset();
                    mensagem.write(quadro.getDados());
                } else if (opcode == QuadroWebSocket.CONTINUACAO) {
                    // Continuacao sem mensagem em andamento = erro de protocolo (1002).
                    if (tipoMensagem == -1) { fechar(1002); break; }
                    mensagem.write(quadro.getDados());
                } else {
                    fechar(1002); // opcode desconhecido
                    break;
                }
                if (opcode == QuadroWebSocket.TEXTO || opcode == QuadroWebSocket.BINARIO || opcode == QuadroWebSocket.CONTINUACAO) {
                    if (mensagem.size() > LIMITE_MENSAGEM) { fechar(1009); break; } // 1009 = mensagem grande demais
                    if (quadro.isFim()) {
                        int tipo = tipoMensagem;
                        byte[] bytes = mensagem.toByteArray();
                        tipoMensagem = -1;
                        mensagem.reset();
                        if (tipo == QuadroWebSocket.BINARIO) { fechar(1003); break; } // 1003: so aceitamos texto
                        String texto = decodificar(bytes);
                        if (texto == null) { fechar(1007); break; } // 1007: payload nao e UTF-8 valido
                        ouvinte.aoReceberTexto(this, texto);
                    }
                }
            }
        } catch (SocketTimeoutException e) {
            fechar(1001); // 1001 = going away: estourou o tempo ocioso de 120s
        } catch (IOException e) {
            // Conexao caiu ou cliente enviou quadro invalido.
        } finally {
            encerrar();
            ouvinte.aoFechar(this);
        }
    }

    /**
     * Decodifica UTF-8 em modo ESTRITO (REPORT): bytes malformados geram excecao em vez
     * do caractere de substituicao, permitindo responder com o codigo 1007 correto.
     *
     * @return texto decodificado ou null se o payload nao for UTF-8 valido
     */
    private static String decodificar(byte[] bytes) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
        } catch (CharacterCodingException e) { return null; }
    }
}