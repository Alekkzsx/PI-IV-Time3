// Desenvolvido por Marcelo Zarpelon

package videocall.hub;

import java.util.Map;

// Recebe os envelopes validados que passam pelo hub, por exemplo para guardar o historico do chat.
public interface RegistradorEnvelope {
    void registrar(String sala, Map<String, Object> envelope);
}
