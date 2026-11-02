// Desenvolvido por Marcelo Zarpelon

package websocket;

import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

// Um quadro (frame) do protocolo WebSocket, RFC 6455 secao 5.
public final class QuadroWebSocket {
    public static final int CONTINUACAO = 0x0;
    public static final int TEXTO = 0x1;
    public static final int BINARIO = 0x2;
    public static final int FECHAR = 0x8;
    public static final int PING = 0x9;
    public static final int PONG = 0xA;

    public static final int TAMANHO_MAXIMO = 65536;

    private final boolean fim;
    private final int opcode;
    private final byte[] dados;

    public QuadroWebSocket(boolean fim, int opcode, byte[] dados) {
        this.fim = fim;
        this.opcode = opcode;
        this.dados = dados;
    }

    public boolean isFim() { return fim; }
    public int getOpcode() { return opcode; }
    public byte[] getDados() { return dados; }
    public boolean isControle() { return (opcode & 0x8) != 0; }

    // Le um quadro enviado pelo cliente; o cliente sempre deve mascarar.
    public static QuadroWebSocket ler(InputStream entrada) throws IOException {
        int b0 = lerByte(entrada);
        int b1 = lerByte(entrada);
        if ((b0 & 0x70) != 0) throw new IOException("Bits RSV nao suportados");
        boolean fim = (b0 & 0x80) != 0;
        int opcode = b0 & 0x0F;
        boolean mascarado = (b1 & 0x80) != 0;
        if (!mascarado) throw new IOException("Quadro do cliente sem mascara");

        long tamanho = b1 & 0x7F;
        if (tamanho == 126) {
            tamanho = (lerByte(entrada) << 8) | lerByte(entrada);
        } else if (tamanho == 127) {
            tamanho = 0;
            for (int i = 0; i < 8; i++) tamanho = (tamanho << 8) | lerByte(entrada);
            if (tamanho < 0) throw new IOException("Tamanho de quadro invalido");
        }
        if (tamanho > TAMANHO_MAXIMO) throw new IOException("Quadro excede o limite de 64 KB");
        boolean controle = (opcode & 0x8) != 0;
        if (controle && (!fim || tamanho > 125)) throw new IOException("Quadro de controle invalido");

        byte[] mascara = entrada.readNBytes(4);
        if (mascara.length != 4) throw new EOFException("Conexao encerrada");
        byte[] dados = entrada.readNBytes((int) tamanho);
        if (dados.length != tamanho) throw new EOFException("Conexao encerrada");
        for (int i = 0; i < dados.length; i++) dados[i] = (byte) (dados[i] ^ mascara[i % 4]);
        return new QuadroWebSocket(fim, opcode, dados);
    }

    // Escreve um quadro do servidor (sem mascara).
    public void escrever(OutputStream saida) throws IOException {
        saida.write((fim ? 0x80 : 0x00) | opcode);
        int tamanho = dados.length;
        if (tamanho < 126) {
            saida.write(tamanho);
        } else if (tamanho <= 0xFFFF) {
            saida.write(126);
            saida.write(tamanho >> 8);
            saida.write(tamanho & 0xFF);
        } else {
            saida.write(127);
            for (int i = 7; i >= 0; i--) saida.write((int) (((long) tamanho >> (8 * i)) & 0xFF));
        }
        saida.write(dados);
        saida.flush();
    }

    private static int lerByte(InputStream entrada) throws IOException {
        int b = entrada.read();
        if (b < 0) throw new EOFException("Conexao encerrada");
        return b;
    }
}
