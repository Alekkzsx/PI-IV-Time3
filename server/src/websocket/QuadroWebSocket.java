// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package websocket;

import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

// Um quadro (frame) do protocolo WebSocket, RFC 6455 secao 5.
/**
 * Um quadro (frame) do protocolo WebSocket, RFC 6455 secao 5.
 *
 * Layout no fio (primeiros bytes):
 *   byte 0: [FIN(1) RSV1-3(3) opcode(4)]
 *   byte 1: [MASK(1) payload-len(7)]  -> 126 = len em 16 bits; 127 = len em 64 bits
 *   [4 bytes de masking-key se MASK=1] [payload XOR mascara]
 *
 * Leitura (ler): apenas quadros DE CLIENTE, que a RFC obriga a vir mascarados.
 * Escrita (escrever): quadros DE SERVIDOR, que a RFC proibe de mascarar.
 */
public final class QuadroWebSocket {
    // Opcodes de dados (bit 3 = 0): continuacao de mensagem fragmentada e os dois tipos de payload.
    public static final int CONTINUACAO = 0x0;
    public static final int TEXTO = 0x1;
    public static final int BINARIO = 0x2;
    // Opcodes de controle (bit 3 = 1): sempre FIN=1 e payload <= 125 bytes.
    public static final int FECHAR = 0x8;
    public static final int PING = 0x9;
    public static final int PONG = 0xA;

    // Teto de 64 KB por quadro: sinalizacao WebRTC/chat sao mensagens pequenas; barra DoS de memoria.
    public static final int TAMANHO_MAXIMO = 65536;

    private final boolean fim;
    private final int opcode;
    private final byte[] dados;

    /** @param fim bit FIN: true quando este quadro encerra a mensagem (unicos frames de controle sao sempre fim). */
    public QuadroWebSocket(boolean fim, int opcode, byte[] dados) {
        this.fim = fim;
        this.opcode = opcode;
        this.dados = dados;
    }

    /** @return bit FIN do quadro (ultimo fragmento da mensagem). */
    public boolean isFim() { return fim; }
    /** @return opcode de 4 bits (TEXTO, BINARIO, CONTINUACAO, FECHAR, PING, PONG). */
    public int getOpcode() { return opcode; }
    /** @return payload ja desmascarado (leitura) ou a mascarar nunca (escrita de servidor). */
    public byte[] getDados() { return dados; }
    /** Bit 3 do opcode separa controle (0x8+) de dados (0x0-0x2). */
    public boolean isControle() { return (opcode & 0x8) != 0; }

    /**
     * Le e desmascara um quadro do cliente, validando as regras da RFC 6455.
     *
     * @throws IOException em fim de stream, RSV nao suportado, quadro sem mascara,
     *                     tamanho acima de 64 KB ou quadro de controle malformado
     */
    public static QuadroWebSocket ler(InputStream entrada) throws IOException {
        int b0 = lerByte(entrada);
        int b1 = lerByte(entrada);
        // RSV1-3 (bits 6-4) so podem ser usados com extensao negociada; aqui nenhuma -> devem ser 0.
        if ((b0 & 0x70) != 0) throw new IOException("Bits RSV nao suportados");
        boolean fim = (b0 & 0x80) != 0;   // bit 7 = FIN
        int opcode = b0 & 0x0F;           // bits 3-0 = opcode
        boolean mascarado = (b1 & 0x80) != 0;
        // RFC 6455 5.1: servidor DEVE derrubar a conexao ao receber quadro de cliente sem mascara.
        if (!mascarado) throw new IOException("Quadro do cliente sem mascara");

        // Comprimento em 3 formas: 0-125 direto; 126 -> proximos 2 bytes; 127 -> proximos 8 bytes (big-endian).
        long tamanho = b1 & 0x7F;
        if (tamanho == 126) {
            tamanho = (lerByte(entrada) << 8) | lerByte(entrada);
        } else if (tamanho == 127) {
            tamanho = 0;
            for (int i = 0; i < 8; i++) tamanho = (tamanho << 8) | lerByte(entrada);
            // Bit mais significativo dos 64 bits deve ser 0; se ficou negativo, o cliente mandou lixo.
            if (tamanho < 0) throw new IOException("Tamanho de quadro invalido");
        }
        if (tamanho > TAMANHO_MAXIMO) throw new IOException("Quadro excede o limite de 64 KB");
        boolean controle = (opcode & 0x8) != 0;
        // Quadros de controle nao podem ser fragmentados nem passar de 125 bytes (RFC 5.5).
        if (controle && (!fim || tamanho > 125)) throw new IOException("Quadro de controle invalido");

        byte[] mascara = lerBytes(entrada, 4);
        byte[] dados = lerBytes(entrada, (int) tamanho);
        // Desmascara: payload[i] XOR masking-key[i mod 4] (RFC 5.3).
        for (int i = 0; i < dados.length; i++) dados[i] = (byte) (dados[i] ^ mascara[i % 4]);
        return new QuadroWebSocket(fim, opcode, dados);
    }

    /**
     * Escreve o quadro no formato de SERVIDOR: MASK=0 (servidor nunca mascara),
     * comprimento na menor forma possivel e payload cru.
     */
    public void escrever(OutputStream saida) throws IOException {
        saida.write((fim ? 0x80 : 0x00) | opcode);
        int tamanho = dados.length;
        if (tamanho < 126) {
            saida.write(tamanho);
        } else if (tamanho <= 0xFFFF) {
            // Forma estendida de 16 bits, big-endian (byte mais significativo primeiro).
            saida.write(126);
            saida.write(tamanho >> 8);
            saida.write(tamanho & 0xFF);
        } else {
            // Forma estendida de 64 bits: 8 bytes big-endian (aqui os 4 altos sao sempre 0).
            saida.write(127);
            for (int i = 7; i >= 0; i--) saida.write((int) (((long) tamanho >> (8 * i)) & 0xFF));
        }
        saida.write(dados);
        saida.flush();
    }

    /** Le exatamente 'tamanho' bytes (read pode entregar parcial); EOF no meio = conexao truncada. */
    private static byte[] lerBytes(InputStream entrada, int tamanho) throws IOException {
        byte[] bytes = new byte[tamanho];
        int total = 0;
        while (total < tamanho) {
            int lidos = entrada.read(bytes, total, tamanho - total);
            if (lidos < 0) throw new EOFException("Conexao encerrada");
            if (lidos > 0) total += lidos;
        }
        return bytes;
    }

    /** Le um unico byte sem sinal (0-255); EOF vira excecao em vez do -1 cru do InputStream. */
    private static int lerByte(InputStream entrada) throws IOException {
        int b = entrada.read();
        if (b < 0) throw new EOFException("Conexao encerrada");
        return b;
    }
}