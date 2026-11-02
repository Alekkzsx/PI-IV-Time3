// Desenvolvido por Marcelo Zarpelon

package api;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Conjunto de campos permitidos em uma colecao; valida e normaliza documentos recebidos pela API.
public final class Esquema {
    private final Map<String, Campo> campos = new LinkedHashMap<>();

    public Esquema(Campo... definicoes) {
        for (Campo campo : definicoes) campos.put(campo.nome, campo);
    }

    public boolean temCampo(String nome) { return campos.containsKey(nome); }

    // Valida um documento. Campos desconhecidos sao rejeitados e o campo "id" nao e aceito aqui.
    // Em modo parcial os campos obrigatorios ausentes sao tolerados.
    public Map<String, Object> validar(Map<String, Object> entrada, boolean parcial) {
        Map<String, Object> limpo = new LinkedHashMap<>();
        for (Map.Entry<String, Object> item : entrada.entrySet()) {
            Campo campo = campos.get(item.getKey());
            if (campo == null) throw new IllegalArgumentException("Campo nao permitido: " + item.getKey());
            Object valor = item.getValue();
            if (valor == null) throw new IllegalArgumentException("Campo nulo: " + campo.nome);
            limpo.put(campo.nome, converter(campo, valor));
        }
        if (!parcial) {
            for (Campo campo : campos.values()) {
                if (campo.obrigatorio && !limpo.containsKey(campo.nome)) {
                    throw new IllegalArgumentException("Campo obrigatorio: " + campo.nome);
                }
            }
        }
        return limpo;
    }

    private static Object converter(Campo campo, Object valor) {
        switch (campo.tipo) {
            case TEXTO:
                if (!(valor instanceof String)) throw new IllegalArgumentException("Campo deve ser texto: " + campo.nome);
                String texto = ((String) valor).trim();
                if (campo.obrigatorio && texto.isEmpty()) throw new IllegalArgumentException("Campo obrigatorio: " + campo.nome);
                if (texto.length() > campo.limite) throw new IllegalArgumentException("Campo muito longo: " + campo.nome);
                return texto;
            case INTEIRO:
                if (!(valor instanceof Long)) throw new IllegalArgumentException("Campo deve ser inteiro: " + campo.nome);
                return valor;
            case DECIMAL:
                if (!(valor instanceof Long) && !(valor instanceof Double)) throw new IllegalArgumentException("Campo deve ser numero: " + campo.nome);
                return ((Number) valor).doubleValue();
            case BOOLEANO:
                if (!(valor instanceof Boolean)) throw new IllegalArgumentException("Campo deve ser booleano: " + campo.nome);
                return valor;
            case LISTA:
                if (!(valor instanceof List)) throw new IllegalArgumentException("Campo deve ser lista: " + campo.nome);
                if (((List<?>) valor).size() > campo.limite) throw new IllegalArgumentException("Lista muito grande: " + campo.nome);
                return valor;
            default:
                throw new IllegalStateException("Tipo desconhecido");
        }
    }
}
