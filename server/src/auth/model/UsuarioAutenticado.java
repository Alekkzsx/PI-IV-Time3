// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.model;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Representa a identidade autenticada extraida do token de login institucional (JWT HS256)
 * ou da conferencia direta com o servico de sessao.
 */
public final class UsuarioAutenticado {
    private final String userId;
    private final String profile;
    private final String sessionId;
    // Versao da sessao: incrementada na troca de senha; token com versao antiga e recusado.
    private final int sessionVersion;
    private final String identity;
    private final String displayName;
    private final String email;
    private final boolean twoFactorEnabled;
    private final String departmentOrCourse;
    private final String campus;
    private final String semester;
    private final String shift;
    // true = senha provisoria: usuario so pode acessar a rota de troca de senha.
    private final boolean requirePasswordChange;
    private final String socialName;
    private final String personalEmail;
    private final String phone;
    private final String biography;
    private final Map<String, Object> preferences;

    /**
     * Construtor canonico (18 campos). Imutavel e defensivo:
     * profile e normalizado para minusculo (RBAC compara com equals exato),
     * strings null viram "" (getters nunca devolvem null) e preferences recebe
     * copia imutavel (caller nao consegue mutar a identidade depois de criada).
     */
    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName,
            String email,
            boolean twoFactorEnabled,
            String departmentOrCourse,
            String campus,
            String semester,
            String shift,
            boolean requirePasswordChange,
            String socialName,
            String personalEmail,
            String phone,
            String biography,
            Map<String, Object> preferences) {
        this.userId = userId;
        this.profile = profile != null ? profile.trim().toLowerCase(Locale.ROOT) : "";
        this.sessionId = sessionId != null ? sessionId : "";
        this.sessionVersion = sessionVersion;
        this.identity = identity != null ? identity : "";
        this.displayName = displayName != null ? displayName : "";
        this.email = email != null ? email : "";
        this.twoFactorEnabled = twoFactorEnabled;
        this.departmentOrCourse = departmentOrCourse != null ? departmentOrCourse : "";
        this.campus = campus != null ? campus : "";
        this.semester = semester != null ? semester : "";
        this.shift = shift != null ? shift : "";
        this.requirePasswordChange = requirePasswordChange;
        this.socialName = socialName != null ? socialName : "";
        this.personalEmail = personalEmail != null ? personalEmail : "";
        this.phone = phone != null ? phone : "";
        this.biography = biography != null ? biography : "";
        this.preferences = preferences != null
                ? Collections.unmodifiableMap(new LinkedHashMap<String, Object>(preferences))
                : Collections.<String, Object>emptyMap();
    }

    /** Construtor de conveniencia (12 campos): identidade academica completa, sem dados de perfil estendido. */
    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName,
            String email,
            boolean twoFactorEnabled,
            String departmentOrCourse,
            String campus,
            String semester,
            String shift) {
        this(userId, profile, sessionId, sessionVersion, identity, displayName, email,
                twoFactorEnabled, departmentOrCourse, campus, semester, shift,
                false, "", "", "", "", null);
    }

    /** Construtor de conveniencia (8 campos): identidade basica + 2FA, sem dados academicos. */
    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName,
            String email,
            boolean twoFactorEnabled) {
        this(userId, profile, sessionId, sessionVersion, identity, displayName, email, twoFactorEnabled, "", "", "", "");
    }

    /** Construtor minimo (6 campos): usado em testes e fluxos que so conhecem id/perfil/sessao. */
    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName) {
        this(userId, profile, sessionId, sessionVersion, identity, displayName, "", false, "", "", "", "");
    }

    /** @return ObjectId hex do usuario no Mongo (sub do JWT). */
    public String getUserId() { return userId; }
    /** @return perfil normalizado em minusculo: aluno | docente | admin. */
    public String getProfile() { return profile; }
    /** @return jti do access token que originou esta identidade (chave da sessao). */
    public String getSessionId() { return sessionId; }
    /** @return versao de sessao gravada no token (comparada com a do banco). */
    public int getSessionVersion() { return sessionVersion; }
    /** @return identificador institucional (RA/matrona/login). */
    public String getIdentity() { return identity; }
    /** @return nome de exibicao. */
    public String getDisplayName() { return displayName; }
    /** @return e-mail institucional. */
    public String getEmail() { return email; }
    /** @return true se o usuario tem 2FA por e-mail habilitado. */
    public boolean isTwoFactorEnabled() { return twoFactorEnabled; }
    /** @return curso (aluno) ou departamento (docente). */
    public String getDepartmentOrCourse() { return departmentOrCourse; }
    /** @return campus institucional. */
    public String getCampus() { return campus; }
    /** @return semestre atual (aluno). */
    public String getSemester() { return semester; }
    /** @return turno (aluno). */
    public String getShift() { return shift; }
    /** @return true se ha troca de senha obrigatoria pendente. */
    public boolean isRequirePasswordChange() { return requirePasswordChange; }
    /** @return nome social (opcional). */
    public String getSocialName() { return socialName; }
    /** @return e-mail pessoal (opcional, usado em recuperacao). */
    public String getPersonalEmail() { return personalEmail; }
    /** @return telefone (opcional). */
    public String getPhone() { return phone; }
    /** @return biografia (opcional). */
    public String getBiography() { return biography; }
    /** @return preferencias de UI em mapa imutavel (nunca null). */
    public Map<String, Object> getPreferences() { return preferences; }

    /** @return true se o perfil e admin (RBAC maximo). */
    public boolean isAdmin() {
        return "admin".equals(profile);
    }

    /** @return true para docente ou admin (perfis que gerenciam atividades/salas). */
    public boolean isDocenteOuAdmin() {
        return "docente".equals(profile) || "admin".equals(profile);
    }

    /** @return true se o perfil e aluno. */
    public boolean isAluno() {
        return "aluno".equals(profile);
    }
}
