// Desenvolvido por Marcelo Zarpelon

package database;

import java.util.List;
import java.util.Map;

// Colecao de documentos identificados pelo campo "id" (texto).
// Os repositorios dependem so desta interface; a persistencia pode ser memoria ou MongoDB.
public interface Colecao {
    // Lista os documentos cujos campos sao iguais aos do filtro (filtro vazio lista tudo).
    List<Map<String, Object>> listar(Map<String, String> filtro);

    // Retorna null se nao existir.
    Map<String, Object> buscar(String id);

    // Lanca IdDuplicadoException se o id ja existir.
    void inserir(Map<String, Object> documento);

    // Retorna false se o id nao existir.
    boolean substituir(String id, Map<String, Object> documento);

    // Retorna false se o id nao existir.
    boolean remover(String id);
}
