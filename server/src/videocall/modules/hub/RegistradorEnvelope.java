// Desenvolvido por Marcelo Zarpelon
package videocall.modules.hub;

import java.util.Map;

/**
 * Contrato para observadores que registram envelopes de videochamada recebidos pelo SalaVideoHub.
 */
public interface RegistradorEnvelope {
    void registrar(String sala, Map<String, Object> envelope);
}
