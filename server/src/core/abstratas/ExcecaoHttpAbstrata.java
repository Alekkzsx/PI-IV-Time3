// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core.abstratas;

/**
 * Superclasse abstrata para excecoes controladas do servidor que possuem
 * status HTTP e codigo semantico padronizados (ex.: 401, 403, 503).
 *
 * Permite tratamento polimorfico unico em HandlerHttpAbstrato.
 * Subclasses: DatabaseUnavailableException (503), JwtAuthValidator.HttpSecurityException
 * (401/403) e ClientePonteAcademica.ExcecaoPonteAcademica (502/503).
 */
public abstract class ExcecaoHttpAbstrata extends RuntimeException {
    private final int statusHttp;
    private final String codigo;

    /** Construtor sem causa raiz (falhas de regra de negocio, nao de infraestrutura). */
    protected ExcecaoHttpAbstrata(int statusHttp, String codigo, String mensagem) {
        this(statusHttp, codigo, mensagem, null);
    }

    /**
     * @param statusHttp codigo HTTP a responder (401, 403, 429, 503...)
     * @param codigo     codigo semantico estavel para o cliente (ex.: invalid_credentials); vazio vira internal_error
     * @param mensagem   texto seguro para exibicao ao usuario final
     * @param causa      excecao original encadeada (nao vai para a resposta)
     */
    protected ExcecaoHttpAbstrata(int statusHttp, String codigo, String mensagem, Throwable causa) {
        super(mensagem, causa);
        this.statusHttp = statusHttp;
        this.codigo = (codigo != null && !codigo.trim().isEmpty()) ? codigo : "internal_error";
    }

    /** @return status HTTP que o handler deve responder. */
    public int getStatusHttp() {
        return statusHttp;
    }

    /** @return codigo semantico do erro (campo "code" do envelope JSON). */
    public String getCodigo() {
        return codigo;
    }
}
