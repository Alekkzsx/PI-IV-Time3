// Desenvolvido por Guilherme Henrique Moreira

package models;
import utils.JsonSimples;

import java.util.LinkedHashMap;
import java.util.Map;

// Representa um usuario do sistema academico.
public class Usuario {
    public String id, nome, email, perfil, curso, status;

    public Usuario(String id, String nome, String email, String perfil, String curso, String status) {
        this.id = id;
        this.nome = nome;
        this.email = email;
        this.perfil = perfil;
        this.curso = curso;
        this.status = status;
    }

    public Map<String, String> campos() {
        Map<String, String> mapa = new LinkedHashMap<>();
        mapa.put("id", id);
        mapa.put("nome", nome);
        mapa.put("email", email);
        mapa.put("perfil", perfil);
        mapa.put("curso", curso);
        mapa.put("status", status);
        return mapa;
    }

    public String json() { return JsonSimples.objeto(campos()); }
}
