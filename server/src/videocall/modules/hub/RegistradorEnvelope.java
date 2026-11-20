// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package videocall.modules.hub;

import java.util.Map;

/**
 * Contrato para observadores que registram envelopes de videochamada recebidos pelo SalaVideoHub.
 * Desacopla o roteamento (hub) da persistencia/telemetria (RegistradorChat) - padrao Observer.
 */
public interface RegistradorEnvelope {
    /**
     * Recebe um envelope JA VALIDADO pelo hub (protocolo/tipo/senderId conferidos).
     * Roda na thread leitora da conexao de origem: implementacoes devem ser rapidas
     * e thread-safe; excecoes nao devem escapar para o hub.
     */
    void registrar(String sala, Map<String, Object> envelope);
}
