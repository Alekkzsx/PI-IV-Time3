// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core.abstratas;

/**
 * Superclasse abstrata para excecoes controladas do servidor que possuem
 * status HTTP e codigo semantico padronizados (ex.: 401, 403, 503).
 *
 * Permite tratamento polimorfico unico em HandlerHttpAbstrato.
 */
public abstract class ExcecaoHttpAbstrata extends RuntimeException {
    private final int statusHttp;
    private final String codigo;

    protected ExcecaoHttpAbstrata(int statusHttp, String codigo, String mensagem) {
        this(statusHttp, codigo, mensagem, null);
    }

    protected ExcecaoHttpAbstrata(int statusHttp, String codigo, String mensagem, Throwable causa) {
        super(mensagem, causa);
        this.statusHttp = statusHttp;
        this.codigo = (codigo != null && !codigo.trim().isEmpty()) ? codigo : "internal_error";
    }

    public int getStatusHttp() {
        return statusHttp;
    }

    public String getCodigo() {
        return codigo;
    }
}
