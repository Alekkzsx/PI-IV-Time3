// Desenvolvido por Marcelo Zarpelon

package database;

// Fabrica de colecoes por nome.
public interface BancoDados {
    Colecao colecao(String nome);
}
