// Desenvolvido por Marcelo Zarpelon e adaptado para Java SE puro (Java 8+)

package videocall.hub;

import utils.Json;
import videocall.VideoCallService;

import java.util.List;
import java.util.Map;

// Teste sem bibliotecas do registro de mensagens de chat e sincronizacao com VideoCallService.
public class RegistradorChatTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static Map<String, Object> env(String tipo, String payload) {
        return Json.analisarObjeto("{\"type\":\"" + tipo + "\",\"senderId\":\"p1\",\"senderName\":\"Ana\",\"timestamp\":1700,\"payload\":" + payload + "}");
    }

    private static String repetir(char c, int vezes) {
        StringBuilder sb = new StringBuilder(vezes);
        for (int i = 0; i < vezes; i++) sb.append(c);
        return sb.toString();
    }

    public static int executar() {
        falhas = 0;
        VideoCallService servico = VideoCallService.getInstance();
        RegistradorChat r = new RegistradorChat(servico);
        String sala = "SALA-CHAT-TESTE";

        r.registrar(sala, env("chat", "{\"text\":\"ola turma\"}"));
        r.registrar(sala, env("chat", "{\"content\":\"so content\"}"));
        r.registrar(sala, env("heartbeat", "{}"));
        r.registrar(sala, env("chat", "{\"text\":\"   \"}"));
        r.registrar(sala, env("chat", "\"nao e objeto\""));

        List<Map<String, Object>> gravadas = r.listarMensagens(sala);
        esperar(gravadas.size() == 2, "RegistradorChat: grava somente chat com texto valido");

        Map<String, Object> m = gravadas.get(0);
        esperar("ola turma".equals(m.get("text"))
                && "Ana".equals(m.get("senderName"))
                && Long.valueOf(1700L).equals(m.get("sentAt")), "RegistradorChat: campos gravados");
        esperar("so content".equals(gravadas.get(1).get("text")), "RegistradorChat: aceita campo content");

        r.registrar(sala, env("chat", "{\"text\":\"" + repetir('x', 3000) + "\"}"));
        esperar(r.listarMensagens(sala).get(2).get("text").toString().length() == 2000, "RegistradorChat: trunca texto longo em 2000 chars");
        esperar(servico.obterOuCriarSala(sala).chatHistory.size() >= 3, "RegistradorChat: sincroniza mensagens no VideoCallService");

        return falhas;
    }

    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes passaram");
    }
}

