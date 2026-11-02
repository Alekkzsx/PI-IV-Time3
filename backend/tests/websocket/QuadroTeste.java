// Desenvolvido por Marcelo Zarpelon

package websocket;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

// Teste sem bibliotecas dos quadros WebSocket, com exemplos da RFC 6455.
public class QuadroTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static byte[] bytes(int... valores) {
        byte[] r = new byte[valores.length];
        for (int i = 0; i < valores.length; i++) r[i] = (byte) valores[i];
        return r;
    }

    static boolean rejeita(byte[] entrada) {
        try { QuadroWebSocket.ler(new ByteArrayInputStream(entrada)); return false; } catch (IOException e) { return true; }
    }

    // Monta um quadro de cliente mascarado com a chave informada.
    static byte[] quadroCliente(int opcode, byte[] dados, int[] mascara) {
        ByteArrayOutputStream s = new ByteArrayOutputStream();
        s.write(0x80 | opcode);
        if (dados.length < 126) s.write(0x80 | dados.length);
        else { s.write(0x80 | 126); s.write(dados.length >> 8); s.write(dados.length & 0xFF); }
        for (int m : mascara) s.write(m);
        for (int i = 0; i < dados.length; i++) s.write(dados[i] ^ mascara[i % 4]);
        return s.toByteArray();
    }

    public static void main(String[] args) throws IOException {
        // Exemplo da RFC: "Hello" mascarado.
        QuadroWebSocket q = QuadroWebSocket.ler(new ByteArrayInputStream(
                bytes(0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58)));
        esperar(q.isFim() && q.getOpcode() == QuadroWebSocket.TEXTO
                && new String(q.getDados(), StandardCharsets.UTF_8).equals("Hello"), "le texto mascarado da RFC");

        // Exemplo da RFC: "Hello" sem mascara (servidor).
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        new QuadroWebSocket(true, QuadroWebSocket.TEXTO, "Hello".getBytes(StandardCharsets.UTF_8)).escrever(saida);
        esperar(Arrays.equals(saida.toByteArray(), bytes(0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f)), "escreve texto da RFC");

        // Tamanho de 16 bits (200 bytes) ida e volta.
        byte[] longo = new byte[200];
        Arrays.fill(longo, (byte) 'a');
        QuadroWebSocket l = QuadroWebSocket.ler(new ByteArrayInputStream(quadroCliente(QuadroWebSocket.TEXTO, longo, new int[] {1, 2, 3, 4})));
        esperar(Arrays.equals(l.getDados(), longo), "le quadro com tamanho de 16 bits");
        saida.reset();
        new QuadroWebSocket(true, QuadroWebSocket.TEXTO, longo).escrever(saida);
        byte[] escrito = saida.toByteArray();
        esperar(escrito[1] == 126 && escrito.length == 4 + 200, "escreve cabecalho de 16 bits");

        esperar(rejeita(bytes(0x81, 0x05, 'H', 'e', 'l', 'l', 'o')), "rejeita quadro sem mascara");
        esperar(rejeita(bytes(0xC1, 0x80, 0, 0, 0, 0)), "rejeita bits RSV");
        esperar(rejeita(bytes(0x09, 0x80, 0, 0, 0, 0)), "rejeita controle fragmentado");
        esperar(rejeita(bytes(0x81, 0xFF, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0)), "rejeita quadro acima do limite");
        esperar(rejeita(bytes(0x81, 0x85, 1, 2, 3, 4, 5)), "rejeita quadro truncado");

        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
