// Desenvolvido por Marcelo Zarpelon

package videocall.hub;

import java.util.Map;

// Recebe envelopes validados do hub para historico ou auditoria.
public interface RegistradorEnvelope {
    void registrar(String sala, Map<String, Object> envelope);
}