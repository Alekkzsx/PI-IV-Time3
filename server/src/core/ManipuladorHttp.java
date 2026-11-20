// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import java.io.IOException;

// Contrato dos manipuladores de requisicao HTTP da plataforma.
public interface ManipuladorHttp {
    void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException;
}

