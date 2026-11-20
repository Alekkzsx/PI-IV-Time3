// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import java.io.IOException;

// Contrato dos manipuladores de requisicao HTTP da plataforma.
/**
 * Contrato dos manipuladores de requisicao HTTP da plataforma (padrao Strategy/Command).
 * Implementado por {@link core.abstratas.HandlerHttpAbstrato} (via Template Method) e
 * registrado por rota em {@link ServidorHttpNativo#registrarRota}. O servidor entrega
 * a requisicao ja parseada e uma resposta ainda nao enviada; o handler decide status,
 * headers e corpo.
 */
public interface ManipuladorHttp {
    /**
     * Processa uma requisicao e escreve exatamente uma resposta.
     *
     * @param requisicao requisicao HTTP ja parseada do socket
     * @param resposta   canal de escrita da resposta (uso unico por requisicao)
     * @throws IOException em falha de I/O no socket ou ao enviar a resposta
     */
    void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException;
}

