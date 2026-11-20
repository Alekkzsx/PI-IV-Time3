// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package videocall.utils;

import auth.model.UsuarioAutenticado;

import java.util.Locale;
import java.util.Map;

/**
 * Funcoes reutilizaveis do dominio VideoCall:
 * sanitizacao de codigo de sala, resolucao segura de identidade/papel
 * e calculo de percentual/classificacao de presenca discente.
 */
public final class VideoCallUtils {
    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private VideoCallUtils() {}

    /**
     * Normaliza o codigo da sala de videochamada para formato seguro em caixa alta.
     * Pipeline: trim -> uppercase -> espacos ao redor de '-' removidos -> espacos viram '-'
     * -> whitelist final [A-Z0-9._-] (qualquer outro caractere e descartado).
     */
    public static String sanitizeRoomCode(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.trim()
                .toUpperCase(Locale.ROOT)
                .replaceAll("\\s*-\\s*", "-")
                .replaceAll("\\s+", "-")
                .replaceAll("[^A-Z0-9._-]", "");
    }

    /**
     * Resolve o papel do participante garantindo precedencia absoluta do perfil do JWT autenticado.
     * Anti-spoofing: aluno autenticado nunca vira "docente" so porque o body pediu.
     */
    public static String resolverPapel(Map<String, String> params, UsuarioAutenticado usuario, String chaveParam) {
        if (usuario != null) {
            return usuario.getProfile();
        }
        return params != null ? params.get(chaveParam) : null;
    }

    /**
     * Resolve o nome de exibicao priorizando o parametro ou caindo no displayName autenticado.
     */
    public static String resolverNome(Map<String, String> params, UsuarioAutenticado usuario, String chaveParam) {
        String nome = params != null ? params.get(chaveParam) : null;
        if ((nome == null || nome.trim().isEmpty()) && usuario != null && !usuario.getDisplayName().isEmpty()) {
            return usuario.getDisplayName();
        }
        return nome;
    }

    /**
     * Resolve o RA/identidade priorizando o parametro ou caindo na identidade do usuario autenticado.
     */
    public static String resolverRa(Map<String, String> params, UsuarioAutenticado usuario, String chaveParam) {
        String ra = params != null ? params.get(chaveParam) : null;
        if ((ra == null || ra.trim().isEmpty()) && usuario != null) {
            return !usuario.getIdentity().isEmpty() ? usuario.getIdentity() : usuario.getUserId();
        }
        return ra;
    }

    /**
     * Calcula percentual de permanencia limitado a 100.0% com uma casa decimal.
     * base minima 1 evita divisao por zero em sala de duracao desconhecida.
     */
    public static double calcularPercentualPresenca(long minutosConectado, int duracaoTotalMinutos) {
        int base = Math.max(1, duracaoTotalMinutos);
        double percentual = ((double) minutosConectado / base) * 100.0;
        if (percentual > 100.0) {
            percentual = 100.0;
        }
        return Math.round(percentual * 10.0) / 10.0;
    }

    /**
     * Classifica o status regimental de presenca com base no percentual conectado:
     * >= 75% presenca integral; >= 50% meia presenca; abaixo disso falta automatica.
     */
    public static String classificarStatusPresenca(double percentual) {
        if (percentual >= 75.0) {
            return "PRESENCA_INTEGRAL";
        }
        if (percentual >= 50.0) {
            return "MEIA_PRESENCA";
        }
        return "FALTA_AUTOMATICA";
    }
}
