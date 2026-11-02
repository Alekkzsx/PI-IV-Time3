// Desenvolvido por Marcelo Zarpelon

package videocall.hub;

import database.BancoMemoria;
import database.Colecao;
import utils.Json;

import java.util.Map;

// Teste sem bibliotecas do registro de mensagens de chat.
public class RegistradorChatTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static Map<String, Object> env(String tipo, String payload) {
        return Json.analisarObjeto("{\"type\":\"" + tipo + "\",\"senderId\":\"p1\",\"senderName\":\"Ana\",\"timestamp\":1700,\"payload\":" + payload + "}");
    }

    public static void main(String[] args) {
        Colecao c = new BancoMemoria().colecao("mensagens_chat");
        RegistradorChat r = new RegistradorChat(c);
        r.registrar("SALA-1", env("chat", "{\"text\":\"ola turma\"}"));
        r.registrar("SALA-1", env("chat", "{\"content\":\"so content\"}"));
        r.registrar("SALA-1", env("heartbeat", "{}"));
        r.registrar("SALA-1", env("chat", "{\"text\":\"   \"}"));
        r.registrar("SALA-1", env("chat", "\"nao e objeto\""));
        esperar(c.listar(Map.of()).size() == 2, "grava so chat com texto");
        Map<String, Object> m = c.listar(Map.of("roomId", "SALA-1")).get(0);
        esperar(m.get("text").equals("ola turma") && m.get("senderName").equals("Ana") && m.get("sentAt").equals(1700L), "campos gravados");
        esperar(c.listar(Map.of("text", "so content")).size() == 1, "aceita campo content");
        r.registrar("SALA-1", env("chat", "{\"text\":\"" + "x".repeat(3000) + "\"}"));
        esperar(c.listar(Map.of("roomId", "SALA-1")).get(2).get("text").toString().length() == 2000, "trunca texto longo");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
