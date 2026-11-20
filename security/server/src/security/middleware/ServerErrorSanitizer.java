// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

/**
 * Sanitizador de erros no lado do servidor que previne divulgação de informações e vazamento de stack traces.
 * Converte exceções brutas de execução Java em payloads JSON opacos e padronizados.
 */
public class ServerErrorSanitizer {

    /**
     * Sanitiza erros de entrada do cliente e requisições malformadas em JSON compatível com a RFC.
     * Nunca expõe stack traces da JVM, caminhos de arquivos ou nomes de classes internas.
     */
    public static String sanitizeException(Throwable t) {
        return "{\"status\": 400, \"error\": \"Bad Request\", \"message\": \"Dados invalidos\"}";
    }

    /**
     * Sanitiza exceções internas não tratadas em payloads JSON opacos de HTTP 500.
     */
    public static String sanitizeInternalError(Throwable t) {
        return "{\"status\": 500, \"error\": \"Internal Server Error\", \"message\": \"Ocorreu um erro interno\"}";
    }
}

