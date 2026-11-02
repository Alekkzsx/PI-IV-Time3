// Desenvolvido por Marcelo Zarpelon

package database;

// Tentativa de inserir um documento com id ja existente.
public class IdDuplicadoException extends RuntimeException {
    public IdDuplicadoException(String id) { super("ID ja cadastrado: " + id); }
}
