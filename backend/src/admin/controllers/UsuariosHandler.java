// Desenvolvido por Guilherme Henrique Moreira

package admin.controllers;

import server.HttpUtils;
import server.ManipuladorHttp;
import server.RequisicaoHttp;
import server.RespostaHttp;
import admin.repositories.UsuarioRepository;
import models.Usuario;
import utils.JsonSimples;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Set;

// Atende a API de gestao de usuarios do ADMIN.
public class UsuariosHandler implements ManipuladorHttp {
    private final UsuarioRepository repositorio;
    private static final String RAIZ = "/api/admin/usuarios";
    private static final Set<String> PERFIS = Set.of("ALUNO", "PROFESSOR", "ADMIN");
    private static final Set<String> STATUS = Set.of("ATIVO", "INATIVO");

    public UsuariosHandler(UsuarioRepository repositorio) { this.repositorio = repositorio; }

    @Override
    public void handle(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        HttpUtils.aplicarHeadersCors(resp);
        if (req.getMetodo().equals("OPTIONS")) { resp.enviar(204, ""); return; }
        String caminho = req.getCaminho();
        String restante = caminho.substring(RAIZ.length());
        String[] partes = restante.isEmpty() ? new String[0] : restante.substring(1).split("/");
        try {
            if (partes.length == 0) {
                if (req.getMetodo().equals("GET")) { listar(resp); return; }
                if (req.getMetodo().equals("POST")) { cadastrar(req, resp); return; }
            } else if (partes.length == 1 && !partes[0].isBlank()) {
                String id = decodificarId(partes[0]);
                if (req.getMetodo().equals("GET")) { buscar(id, resp); return; }
                if (req.getMetodo().equals("PUT")) { atualizar(id, req, resp); return; }
            } else if (partes.length == 2 && partes[1].equals("status") && req.getMetodo().equals("PATCH")) {
                status(decodificarId(partes[0]), req, resp); return;
            }
            enviar(resp, 405, "Metodo ou caminho nao permitido");
        } catch (IllegalArgumentException e) { enviar(resp, 400, e.getMessage()); }
    }

    private String decodificarId(String id) {
        if (!id.matches("[a-zA-Z0-9._-]{1,60}")) throw new IllegalArgumentException("ID invalido");
        return id;
    }

    private Map<String, String> dados(RequisicaoHttp req, String... permitidos) {
        Map<String, String> mapa = JsonSimples.analisar(req.getCorpo());
        Set<String> campos = Set.of(permitidos);
        for (String campo : mapa.keySet()) if (!campos.contains(campo)) throw new IllegalArgumentException("Campo nao permitido: " + campo);
        return mapa;
    }

    private String obrigatorio(Map<String, String> dados, String campo, int limite) {
        String valor = dados.getOrDefault(campo, "").trim();
        if (valor.isBlank() || valor.length() > limite) throw new IllegalArgumentException("Campo obrigatorio ou muito longo: " + campo);
        return valor;
    }

    private Usuario montar(Map<String, String> dados, String id) {
        String nome = obrigatorio(dados, "nome", 120);
        String email = obrigatorio(dados, "email", 180).toLowerCase(java.util.Locale.ROOT);
        String perfil = obrigatorio(dados, "perfil", 20).toUpperCase(java.util.Locale.ROOT);
        String curso = dados.getOrDefault("curso", "").trim();
        String status = dados.getOrDefault("status", "ATIVO").trim().toUpperCase(java.util.Locale.ROOT);
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new IllegalArgumentException("Email invalido");
        if (!PERFIS.contains(perfil)) throw new IllegalArgumentException("Perfil deve ser ALUNO, PROFESSOR ou ADMIN");
        if (!STATUS.contains(status)) throw new IllegalArgumentException("Status deve ser ATIVO ou INATIVO");
        if (curso.length() > 160) throw new IllegalArgumentException("Curso muito longo");
        return new Usuario(id, nome, email, perfil, curso, status);
    }

    private void listar(RespostaHttp resp) throws IOException {
        List<Usuario> lista = repositorio.listar();
        StringBuilder json = new StringBuilder("{\"usuarios\":[");
        for (Usuario u : lista) { if (json.charAt(json.length() - 1) != '[') json.append(','); json.append(u.json()); }
        respJson(resp, 200, json.append("]}").toString());
    }

    private void buscar(String id, RespostaHttp resp) throws IOException {
        Usuario u = repositorio.buscar(id);
        if (u == null) { enviar(resp, 404, "Usuario nao encontrado"); return; }
        respJson(resp, 200, u.json());
    }

    private void cadastrar(RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> mapa = dados(req, "id", "nome", "email", "perfil", "curso", "status");
        String id = decodificarId(obrigatorio(mapa, "id", 60));
        Usuario u = montar(mapa, id);
        synchronized (repositorio) {
            if (repositorio.buscar(id) != null) { enviar(resp, 409, "ID ja cadastrado"); return; }
            if (repositorio.existeEmail(u.email, id)) { enviar(resp, 409, "Email ja cadastrado"); return; }
            repositorio.gravar(u);
        }
        respJson(resp, 201, u.json());
    }

    private void atualizar(String id, RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> mapa = dados(req, "nome", "email", "perfil", "curso", "status");
        synchronized (repositorio) {
            if (repositorio.buscar(id) == null) { enviar(resp, 404, "Usuario nao encontrado"); return; }
            Usuario u = montar(mapa, id);
            if (repositorio.existeEmail(u.email, id)) { enviar(resp, 409, "Email ja cadastrado"); return; }
            repositorio.gravar(u);
            respJson(resp, 200, u.json());
        }
    }

    private void status(String id, RequisicaoHttp req, RespostaHttp resp) throws IOException {
        Map<String, String> mapa = dados(req, "status");
        String novo = obrigatorio(mapa, "status", 20).toUpperCase(java.util.Locale.ROOT);
        if (!STATUS.contains(novo)) throw new IllegalArgumentException("Status deve ser ATIVO ou INATIVO");
        synchronized (repositorio) {
            Usuario antigo = repositorio.buscar(id);
            if (antigo == null) { enviar(resp, 404, "Usuario nao encontrado"); return; }
            Usuario u = new Usuario(id, antigo.nome, antigo.email, antigo.perfil, antigo.curso, novo);
            repositorio.gravar(u);
            respJson(resp, 200, u.json());
        }
    }

    private void enviar(RespostaHttp resp, int codigo, String mensagem) throws IOException {
        respJson(resp, codigo, "{\"erro\":" + JsonSimples.escapar(mensagem) + "}");
    }

    private void respJson(RespostaHttp resp, int codigo, String json) throws IOException {
        resp.adicionarCabecalho("Content-Type", "application/json; charset=utf-8");
        resp.enviar(codigo, json);
    }
}
