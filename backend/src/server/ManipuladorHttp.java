// Desenvolvido por Guilherme Henrique Moreira
package server;

import java.io.IOException;

// Contrato simples dos handlers da API.
public interface ManipuladorHttp {
    void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException;
}
