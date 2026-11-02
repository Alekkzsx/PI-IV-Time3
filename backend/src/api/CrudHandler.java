// Desenvolvido por Marcelo Zarpelon

package api;

import database.Colecao;
import database.IdDuplicadoException;
import server.HttpUtils;
import server.ManipuladorHttp;
import server.RequisicaoHttp;
import server.RespostaHttp;
import utils.Json;
import utils.JsonSimples;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.UnaryOperator;

// CRUD REST generico sobre uma colecao: GET lista, POST cria, GET/PUT/PATCH/DELETE por id.
public class CrudHandler implements ManipuladorHttp {
    private final String raiz;
    private final Colecao colecao;
    private final Esquema esquema;
    // Transformacao aplicada aos documentos antes de enviar (ex.: campos calculados); nao altera o que esta no banco.
    private UnaryOperator<Map<String, Object>> saida = documento -> documento;

    public CrudHandler(String raiz, Colecao colecao, Esquema esquema) {
        this.raiz = raiz;
        this.colecao = colecao;
        this.esquema = esquema;
    }

    public CrudHandler comSaida(UnaryOperator<Map<String, Object>> transformacao) {
        this.saida = transformacao;
        return this;
    }

    private Map<String, Object> paraSaida(Map<String, Object> documento) {
        return saida.apply(new LinkedHashMap<>(documento));
    }

    @Override
    public void handle(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        HttpUtils.aplicarHeadersCors(resp);
        String metodo = req.getMetodo();
        if (metodo.equals("OPTIONS")) { resp.enviar(204, ""); return; }
        String restante = req.getCaminho().substring(raiz.length());
        try {
            if (restante.isEmpty()) {
                if (metodo.equals("GET")) { listar(req, resp); return; }
                if (metodo.equals("POST")) { criar(req, resp); return; }
            } else if (restante.startsWith("/") && restante.indexOf('/', 1) < 0) {
                String id = validarId(restante.substring(1));
                if (metodo.equals("GET")) { buscar(id, resp); return; }
                if (metodo.equals("PUT")) { alterar(id, req, resp, false); return; }
                if (metodo.equals("PATCH")) { alterar(id, req, resp, true); return; }
                if (metodo.equals("DELETE")) { remover(id, resp); return; }
            }
            erro(resp, 405, "Metodo ou caminho nao permitido");
        } catch (IllegalArgumentException e) {
            erro(resp, 400, e.getMessage());
        }
    }

    private static String validarId(String id) {
        if (!id.matches("[a-zA-Z0-9._-]{1,60}")) throw new IllegalArgumentException("ID invalido");
        return id;
    }

    private void listar(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> filtro = new LinkedHashMap<>();
        for (Map.Entry<String, String> item : HttpUtils.parseFormUrlEncoded(req.getConsulta()).entrySet()) {
            if (!item.getKey().equals("id") && !esquema.temCampo(item.getKey())) {
                throw new IllegalArgumentException("Filtro nao permitido: " + item.getKey());
            }
            filtro.put(item.getKey(), item.getValue());
        }
        List<Map<String, Object>> itens = new java.util.ArrayList<>();
        for (Map<String, Object> documento : colecao.listar(filtro)) itens.add(paraSaida(documento));
        Map<String, Object> corpo = new LinkedHashMap<>();
        corpo.put("itens", itens);
        json(resp, 200, Json.escrever(corpo));
    }

    private void buscar(String id, RespostaHttp resp) throws IOException {
        Map<String, Object> documento = colecao.buscar(id);
        if (documento == null) { erro(resp, 404, "Registro nao encontrado"); return; }
        json(resp, 200, Json.escrever(paraSaida(documento)));
    }

    private void criar(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, Object> corpo = Json.analisarObjeto(req.getCorpo());
        Object informado = corpo.remove("id");
        String id;
        if (informado == null) id = UUID.randomUUID().toString();
        else if (informado instanceof String) id = validarId((String) informado);
        else throw new IllegalArgumentException("ID invalido");
        Map<String, Object> documento = comId(id, esquema.validar(corpo, false));
        try {
            colecao.inserir(documento);
        } catch (IdDuplicadoException e) {
            erro(resp, 409, "ID ja cadastrado");
            return;
        }
        json(resp, 201, Json.escrever(paraSaida(documento)));
    }

    private void alterar(String id, RequisicaoHttp req, RespostaHttp resp, boolean parcial) throws IOException {
        Map<String, Object> corpo = Json.analisarObjeto(req.getCorpo());
        Map<String, Object> validado = esquema.validar(corpo, parcial);
        Map<String, Object> atual = colecao.buscar(id);
        if (atual == null) { erro(resp, 404, "Registro nao encontrado"); return; }
        Map<String, Object> documento;
        if (parcial) {
            documento = new LinkedHashMap<>(atual);
            documento.putAll(validado);
        } else {
            documento = comId(id, validado);
        }
        if (!colecao.substituir(id, documento)) { erro(resp, 404, "Registro nao encontrado"); return; }
        json(resp, 200, Json.escrever(paraSaida(documento)));
    }

    private void remover(String id, RespostaHttp resp) throws IOException {
        if (!colecao.remover(id)) { erro(resp, 404, "Registro nao encontrado"); return; }
        resp.enviar(204, "");
    }

    // O id fica sempre como primeiro campo do documento.
    private static Map<String, Object> comId(String id, Map<String, Object> campos) {
        Map<String, Object> documento = new LinkedHashMap<>();
        documento.put("id", id);
        documento.putAll(campos);
        return documento;
    }

    private static void erro(RespostaHttp resp, int codigo, String mensagem) throws IOException {
        json(resp, codigo, "{\"erro\":" + JsonSimples.escapar(mensagem) + "}");
    }

    private static void json(RespostaHttp resp, int codigo, String json) throws IOException {
        resp.adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        resp.enviar(codigo, json);
    }
}
