// Desenvolvido por Marcelo Zarpelon - RA: 25015323

package websocket;

// Recebe os eventos de uma conexao WebSocket.
/**
 * Recebe os eventos de uma conexao WebSocket (padrao Observer).
 * Implementado por SalaVideoHub, que roteia mensagens por sala.
 * Atencao a threading: os tres callbacks rodam na thread leitora da propria
 * ConexaoWebSocket - implementacoes devem ser thread-safe e nao bloquear.
 */
public interface OuvinteWebSocket {
    /** Conexao estabelecida (handshake 101 concluido); momento de registrar no hub. */
    void aoAbrir(ConexaoWebSocket conexao);

    /** Mensagem de texto completa (fragmentos ja remontados e UTF-8 validado). */
    void aoReceberTexto(ConexaoWebSocket conexao, String texto);

    /** Conexao encerrada (por qualquer motivo); momento de remover do hub e limpar presenca. */
    void aoFechar(ConexaoWebSocket conexao);
}