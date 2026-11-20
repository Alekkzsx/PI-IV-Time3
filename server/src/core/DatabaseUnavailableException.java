// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
package core;

import com.mongodb.MongoConfigurationException;
import com.mongodb.MongoSocketException;
import com.mongodb.MongoTimeoutException;
import com.mongodb.spi.dns.DnsException;
import core.abstratas.ExcecaoHttpAbstrata;

import javax.naming.NamingException;
import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;

/**
 * Excecao controlada para falhas de conectividade de rede/DNS com o MongoDB
 * (ex.: bloqueio de DNS SRV ou porta 27017 em redes corporativas e universitarias).
 */
public class DatabaseUnavailableException extends ExcecaoHttpAbstrata {

    /** Atalho com status 503 (Service Unavailable), o caso quase universal de banco fora do ar. */
    public DatabaseUnavailableException(String codigo, String message, Throwable cause) {
        this(503, codigo, message, cause);
    }

    /** @param codigo codigo semantico (database_dns_blocked, database_network_blocked...); vazio vira database_unavailable. */
    public DatabaseUnavailableException(int statusHttp, String codigo, String message, Throwable cause) {
        super(statusHttp, codigo != null ? codigo : "database_unavailable", message, cause);
    }

    /**
     * Traduz qualquer falha do driver em excecao HTTP amigavel, caminhando pela cadeia
     * de causas (getCause) para classificar a raiz: DNS bloqueado (SRV/TXT), rede/porta
     * bloqueada (timeout/socket) ou indisponibilidade generica. DNS tem prioridade sobre
     * timeout porque um SRV bloqueado costuma aparecer embrulhado em MongoTimeoutException.
     *
     * @param error excecao original capturada do driver/rede
     * @return excecao 503 com codigo e mensagem orientados ao usuario final
     */
    public static DatabaseUnavailableException fromThrowable(Throwable error) {
        if (error instanceof DatabaseUnavailableException) {
            return (DatabaseUnavailableException) error;
        }
        // Percorre toda a cadeia de causas: o driver embrulha a falha real em varias camadas.
        Throwable cursor = error;
        boolean dnsFailure = false;
        boolean networkTimeoutOrSocket = false;
        while (cursor != null) {
            String msg = cursor.getMessage() != null ? cursor.getMessage().toLowerCase() : "";
            if (cursor instanceof DnsException
                    || cursor instanceof NamingException
                    || cursor instanceof UnknownHostException
                    || (cursor instanceof MongoConfigurationException
                        && (msg.contains("srv") || msg.contains("txt") || msg.contains("dns")))) {
                dnsFailure = true;
            }
            if (cursor instanceof MongoTimeoutException
                    || cursor instanceof MongoSocketException
                    || cursor instanceof ConnectException
                    || cursor instanceof SocketTimeoutException) {
                networkTimeoutOrSocket = true;
            }
            cursor = cursor.getCause();
        }
        if (dnsFailure) {
            return new DatabaseUnavailableException(
                    503,
                    "database_dns_blocked",
                    "Banco de dados inacessivel: esta rede bloqueou a resolucao DNS SRV do MongoDB Atlas.",
                    error
            );
        }
        if (networkTimeoutOrSocket) {
            return new DatabaseUnavailableException(
                    503,
                    "database_network_blocked",
                    "Banco de dados inacessivel a partir desta rede (verifique se a porta 27017 ou VPN esta bloqueada no Wi-Fi).",
                    error
            );
        }
        return new DatabaseUnavailableException(
                503,
                "database_unavailable",
                "Servico de dados temporariamente indisponivel para validar a autenticacao.",
                error
        );
    }
}
