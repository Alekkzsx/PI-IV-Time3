// Desenvolvido por Marcelo Zarpelon

package api;

import database.BancoMemoria;
import server.RequisicaoHttp;
import server.RespostaHttp;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

// Teste sem bibliotecas do CRUD generico, chamando o handler com requisicoes montadas em memoria.
public class CrudHandlerTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    // Retorna a resposta HTTP completa como texto.
    static String chamar(CrudHandler h, String metodo, String caminho, String corpo) throws IOException {
        byte[] b = corpo.getBytes(StandardCharsets.UTF_8);
        String pedido = metodo + " " + caminho + " HTTP/1.1\r\nHost: x\r\nContent-Length: " + b.length + "\r\n\r\n" + corpo;
        RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(pedido.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        h.handle(req, new RespostaHttp(saida));
        return saida.toString(StandardCharsets.UTF_8);
    }

    static boolean status(String resposta, int codigo) { return resposta.startsWith("HTTP/1.1 " + codigo + " "); }

    public static void main(String[] args) throws IOException {
        Esquema e = new Esquema(Campo.texto("titulo", true, 50), Campo.texto("cursoId", true, 60), Campo.decimal("peso", false));
        CrudHandler h = new CrudHandler("/api/docente/tarefas", new BancoMemoria().colecao("tarefas"), e);
        String raiz = "/api/docente/tarefas";

        String r = chamar(h, "POST", raiz, "{\"id\":\"t1\",\"titulo\":\"P1\",\"cursoId\":\"c1\",\"peso\":0.4}");
        esperar(status(r, 201) && r.contains("\"id\":\"t1\""), "POST cria com id informado");
        r = chamar(h, "POST", raiz, "{\"titulo\":\"P2\",\"cursoId\":\"c2\"}");
        esperar(status(r, 201) && r.contains("\"id\":\""), "POST gera id quando ausente");
        esperar(status(chamar(h, "POST", raiz, "{\"id\":\"t1\",\"titulo\":\"X\",\"cursoId\":\"c\"}"), 409), "POST id repetido da 409");
        esperar(status(chamar(h, "POST", raiz, "{\"titulo\":\"X\"}"), 400), "POST sem campo obrigatorio da 400");
        esperar(status(chamar(h, "POST", raiz, "{\"titulo\":\"X\",\"cursoId\":\"c\",\"hack\":1}"), 400), "POST campo desconhecido da 400");
        esperar(status(chamar(h, "POST", raiz, "nao e json"), 400), "POST json invalido da 400");

        r = chamar(h, "GET", raiz, "");
        esperar(status(r, 200) && r.contains("\"itens\":[") && r.contains("P1") && r.contains("P2"), "GET lista");
        r = chamar(h, "GET", raiz + "?cursoId=c1", "");
        esperar(r.contains("P1") && !r.contains("P2"), "GET filtra por query");
        esperar(status(chamar(h, "GET", raiz + "?senha=x", ""), 400), "GET filtro fora do esquema da 400");
        esperar(status(chamar(h, "GET", raiz + "/t1", ""), 200), "GET por id");
        esperar(status(chamar(h, "GET", raiz + "/zz", ""), 404), "GET inexistente da 404");
        esperar(status(chamar(h, "GET", raiz + "/a%20b", ""), 400), "GET id invalido da 400");

        r = chamar(h, "PATCH", raiz + "/t1", "{\"titulo\":\"P1 novo\"}");
        esperar(status(r, 200) && r.contains("P1 novo") && r.contains("\"cursoId\":\"c1\""), "PATCH altera so os campos enviados");
        esperar(status(chamar(h, "PUT", raiz + "/t1", "{\"titulo\":\"so titulo\"}"), 400), "PUT exige todos os obrigatorios");
        r = chamar(h, "PUT", raiz + "/t1", "{\"titulo\":\"T\",\"cursoId\":\"c9\"}");
        esperar(status(r, 200) && !r.contains("peso"), "PUT substitui o documento");
        esperar(status(chamar(h, "PUT", raiz + "/zz", "{\"titulo\":\"T\",\"cursoId\":\"c9\"}"), 404), "PUT inexistente da 404");

        esperar(status(chamar(h, "DELETE", raiz + "/t1", ""), 204), "DELETE remove");
        esperar(status(chamar(h, "DELETE", raiz + "/t1", ""), 404), "DELETE repetido da 404");
        esperar(status(chamar(h, "PUT", raiz, "{}"), 405), "metodo nao permitido na raiz");
        esperar(status(chamar(h, "OPTIONS", raiz, ""), 204), "OPTIONS responde 204");

        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
