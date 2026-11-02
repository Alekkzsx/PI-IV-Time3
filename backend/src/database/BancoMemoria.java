// Desenvolvido por Marcelo Zarpelon

package database;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Banco em memoria, usado nos testes e como alternativa quando o MongoDB nao esta configurado.
public class BancoMemoria implements BancoDados {
    private final Map<String, Colecao> colecoes = new HashMap<>();

    @Override
    public synchronized Colecao colecao(String nome) {
        return colecoes.computeIfAbsent(nome, k -> new ColecaoMemoria());
    }

    private static class ColecaoMemoria implements Colecao {
        private final Map<String, Map<String, Object>> documentos = new LinkedHashMap<>();

        private static String id(Map<String, Object> documento) {
            Object id = documento.get("id");
            if (!(id instanceof String) || ((String) id).isBlank()) throw new IllegalArgumentException("Documento sem id");
            return (String) id;
        }

        @Override
        public synchronized List<Map<String, Object>> listar(Map<String, String> filtro) {
            List<Map<String, Object>> resultado = new ArrayList<>();
            for (Map<String, Object> documento : documentos.values()) {
                boolean combina = true;
                for (Map.Entry<String, String> condicao : filtro.entrySet()) {
                    Object valor = documento.get(condicao.getKey());
                    if (valor == null || !String.valueOf(valor).equals(condicao.getValue())) { combina = false; break; }
                }
                if (combina) resultado.add(new LinkedHashMap<>(documento));
            }
            return resultado;
        }

        @Override
        public synchronized Map<String, Object> buscar(String id) {
            Map<String, Object> documento = documentos.get(id);
            return documento == null ? null : new LinkedHashMap<>(documento);
        }

        @Override
        public synchronized void inserir(Map<String, Object> documento) {
            String id = id(documento);
            if (documentos.containsKey(id)) throw new IdDuplicadoException(id);
            documentos.put(id, new LinkedHashMap<>(documento));
        }

        @Override
        public synchronized boolean substituir(String id, Map<String, Object> documento) {
            if (!documentos.containsKey(id)) return false;
            documentos.put(id, new LinkedHashMap<>(documento));
            return true;
        }

        @Override
        public synchronized boolean remover(String id) { return documentos.remove(id) != null; }
    }
}
