// Desenvolvido por Murillo Caravita - RA: 25014012
package auth.utils;

import auth.model.UsuarioAutenticado;
import org.bson.Document;
import utils.ConfigEnv;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Funcoes reutilizaveis compartilhadas pelos modulos de autenticacao, conta e administracao.
 * Elimina duplicacao de mascaramento de e-mail, latencia anti-timing, configuracao de OTP
 * e montagem de payloads JSON de usuario/perfil.
 */
public final class AuthHttpUtils {
    // Fallback de desenvolvimento: em producao AUTH_OTP_SECRET deve ser definido no .env
    // (segredo publico no codigo nao protege os digests de OTP de um vazamento do banco).
    private static final String OTP_SECRET_FALLBACK =
            "agmrm-otp-secret-key-2026-recovery-verification-1a2b3c4d5e6f7890";

    // Classe utilitaria estatica: construtor privado impede instanciacao.
    private AuthHttpUtils() {}

    /** Segredo HMAC dos OTPs (AUTH_OTP_SECRET do .env, com fallback de dev). */
    public static String obterSegredoOtp() {
        return ConfigEnv.obter("AUTH_OTP_SECRET", OTP_SECRET_FALLBACK);
    }

    /** Validade do OTP em segundos (AUTH_OTP_TTL_SECONDS, default 300 = 5min). */
    public static int obterTtlOtpSegundos() {
        return ConfigEnv.obterInteiro("AUTH_OTP_TTL_SECONDS", 300);
    }

    /**
     * Mascara o e-mail para exibicao segura (ex.: "a***o@dominio.edu").
     * Preserva primeiro e ultimo char do usuario local; local de 1-2 chars mostra so o
     * primeiro (mascarar tudo entregaria o tamanho exato). Dominio fica visivel para o
     * usuario reconhecer a caixa postal sem revelar o endereco completo.
     */
    public static String mascararEmail(String email) {
        if (email == null || email.isEmpty()) {
            return "";
        }
        int arroba = email.indexOf('@');
        if (arroba <= 1) {
            return email;
        }
        String usuario = email.substring(0, arroba);
        String dominio = email.substring(arroba + 1);
        if (usuario.length() <= 2) {
            return usuario.charAt(0) + "***@" + dominio;
        }
        return usuario.charAt(0) + "***" + usuario.charAt(usuario.length() - 1) + "@" + dominio;
    }

    /**
     * Aplica latencia padronizada (opcionalmente com jitter) para mitigar ataques de temporizacao.
     * Completa o tempo TOTAL da resposta ate STANDARDIZED_AUTH_LATENCY_MS (default 1s):
     * caminho feliz e caminho de erro demoram o mesmo, escondendo se o usuario existe,
     * se o hash foi conferido etc. Jitter (+/- aleatorio) evita fingerprint do valor fixo.
     *
     * @param inicioProcessamento epoch ms do inicio do handler (0 = nao mede decorrido)
     * @param comJitter           adiciona ruido aleatorio de STANDARDIZED_AUTH_JITTER_MS
     */
    public static void aplicarLatenciaPadronizada(long inicioProcessamento, boolean comJitter) {
        long latenciaAlvo = ConfigEnv.obterInteiro("STANDARDIZED_AUTH_LATENCY_MS", 1000);
        if (latenciaAlvo <= 0) {
            return;
        }
        long decorrido = inicioProcessamento > 0
                ? (System.currentTimeMillis() - inicioProcessamento)
                : 0L;
        long restante = latenciaAlvo - decorrido;
        if (restante <= 0) {
            return;
        }
        long espera = restante;
        if (comJitter) {
            long jitter = ConfigEnv.obterInteiro("STANDARDIZED_AUTH_JITTER_MS", 25);
            long jitterReal = (long) (Math.random() * jitter * 2) - jitter;
            espera = Math.max(0L, restante + jitterReal);
        }
        try {
            Thread.sleep(espera);
        } catch (InterruptedException e) {
            // Restaura a flag de interrupcao: engolir o interrupt quebraria o shutdown do pool.
            Thread.currentThread().interrupt();
        }
    }

    /**
     * Monta o payload de usuario retornado em login, 2FA e renovacao de tokens.
     * Emite aliases pt/en (identidade/identity, perfil/profile, nome/displayName) para
     * compatibilidade entre versoes do frontend; campos vazios sao omitidos.
     */
    public static Map<String, Object> montarPayloadUsuario(
            UsuarioAutenticado usuario,
            boolean incluirCamposAcademicos) {
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("id", usuario.getUserId());
        payload.put("identidade", usuario.getIdentity());
        payload.put("identity", usuario.getIdentity());
        payload.put("perfil", usuario.getProfile());
        payload.put("profile", usuario.getProfile());
        if (!usuario.getDisplayName().isEmpty()) {
            payload.put("nome", usuario.getDisplayName());
            payload.put("displayName", usuario.getDisplayName());
        }
        if (!usuario.getEmail().isEmpty()) {
            payload.put("email", usuario.getEmail());
        }
        if (incluirCamposAcademicos) {
            if (!usuario.getDepartmentOrCourse().isEmpty()) {
                payload.put("departmentOrCourse", usuario.getDepartmentOrCourse());
                payload.put("department", usuario.getDepartmentOrCourse());
            }
            if (!usuario.getCampus().isEmpty()) {
                payload.put("campus", usuario.getCampus());
            }
            if (!usuario.getSemester().isEmpty()) {
                payload.put("semester", usuario.getSemester());
            }
            if (!usuario.getShift().isEmpty()) {
                payload.put("shift", usuario.getShift());
            }
        }
        payload.put("twoFactorRequired", Boolean.valueOf(usuario.isTwoFactorEnabled()));
        payload.put("requirePasswordChange", Boolean.valueOf(usuario.isRequirePasswordChange()));
        return payload;
    }

    /**
     * Monta o perfil publico completo retornado por /api/auth/me, /session e PATCH /profile.
     * campus/semester tem defaults de exibicao; lastLogin aceita os dois nomes de campo
     * historicos do schema (lastLogin e lastLoginAt).
     *
     * @param doc documento auth_users do banco (pode ser null; so enriquece o lastLogin)
     */
    public static Map<String, Object> montarPerfilPublico(UsuarioAutenticado u, Document doc) {
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("id", u.getUserId());
        payload.put("userId", u.getUserId());
        payload.put("identity", u.getIdentity());
        payload.put("displayName", u.getDisplayName());
        payload.put("socialName", u.getSocialName());
        payload.put("email", u.getEmail());
        payload.put("personalEmail", u.getPersonalEmail());
        payload.put("phone", u.getPhone());
        payload.put("biography", u.getBiography());
        payload.put("profile", u.getProfile());
        payload.put("departmentOrCourse", u.getDepartmentOrCourse());
        payload.put("department", u.getDepartmentOrCourse());
        payload.put("campus", !u.getCampus().isEmpty() ? u.getCampus() : "Campus Central");
        payload.put("semester", !u.getSemester().isEmpty() ? u.getSemester() : "2026/2");
        payload.put("shift", u.getShift());
        payload.put("requirePasswordChange", Boolean.valueOf(u.isRequirePasswordChange()));
        payload.put("twoFactorRequired", Boolean.valueOf(u.isTwoFactorEnabled()));
        payload.put("twoFactorEnabled", Boolean.valueOf(u.isTwoFactorEnabled()));
        payload.put("preferences", u.getPreferences() != null
                ? u.getPreferences()
                : new LinkedHashMap<String, Object>());
        Date lastLogin = doc != null
                ? (doc.getDate("lastLogin") != null ? doc.getDate("lastLogin") : doc.getDate("lastLoginAt"))
                : null;
        payload.put("lastLogin", lastLogin);
        return payload;
    }

    /**
     * Serializa um documento BSON de auth_users para visualizacao administrativa segura (sem passwordHash).
     * Whitelist de campos: nada de hash, segredos 2FA ou backup codes sai daqui;
     * departmentOrCourse e twoFactorRequired consolidam nomes de campo legados.
     */
    public static Map<String, Object> montarUsuarioAdmin(Document document) {
        Map<String, Object> map = new LinkedHashMap<String, Object>();
        map.put("id", document.getObjectId("_id").toHexString());
        String identity = document.getString("identity");
        map.put("identity", identity != null ? identity : document.getString("normalizedIdentity"));
        map.put("email", document.getString("email"));
        map.put("displayName", document.getString("displayName"));
        map.put("profile", document.getString("profile"));
        map.put("active", Boolean.valueOf(document.getBoolean("active", false)));
        String dept = document.getString("departmentOrCourse");
        if (dept == null) {
            dept = document.getString("department");
        }
        map.put("departmentOrCourse", dept != null ? dept : "");
        boolean twoFa = document.getBoolean("twoFactorRequired", false)
                || document.getBoolean("twoFactorEnabled", false);
        map.put("twoFactorRequired", Boolean.valueOf(twoFa));
        map.put("suspensionReason", document.get("suspensionReason"));
        Date lastLogin = document.getDate("lastLogin") != null
                ? document.getDate("lastLogin")
                : document.getDate("lastLoginAt");
        map.put("lastLogin", lastLogin);
        map.put("requirePasswordChange", Boolean.valueOf(document.getBoolean("requirePasswordChange", false)));
        return map;
    }

    /**
     * Converte inteiro de query string respeitando limites minimo e maximo.
     * Valor invalido/ausente -> default; fora da faixa -> clamp (protege paginacao de
     * valores absurdos como limit=999999).
     */
    public static int parseIntBounded(String raw, int defaultVal, int min, int max) {
        if (raw == null || raw.trim().isEmpty()) {
            return defaultVal;
        }
        try {
            int val = Integer.parseInt(raw.trim());
            return Math.max(min, Math.min(max, val));
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }
}
