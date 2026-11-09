// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import java.util.Locale;

/**
 * Representa a identidade autenticada extraida do token de login institucional (JWT HS256)
 * ou da conferencia direta com o servico de sessao.
 *
 * Campos adicionados para suporte completo de autenticacao:
 * - email: endereco de email do usuario (para 2FA e recuperacao)
 * - twoFactorEnabled: indica se o 2FA esta ativado para este usuario
 */
public final class UsuarioAutenticado {
    private final String userId;
    private final String profile;
    private final String sessionId;
    private final int sessionVersion;
    private final String identity;
    private final String displayName;
    private final String email;
    private final boolean twoFactorEnabled;
    private final String departmentOrCourse;
    private final String campus;
    private final String semester;
    private final String shift;

    /**
     * Construtor completo com todos os campos institucionais e academicos.
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
            String shift) {
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
    }

    /**
     * Construtor sem campos academicos (mantido para retrocompatibilidade).
     */
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

    /**
     * Construtor de compatibilidade antigo (sem email, 2FA e dados academicos).
     */
    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName) {
        this(userId, profile, sessionId, sessionVersion, identity, displayName, "", false, "", "", "", "");
    }

    public String getUserId() { return userId; }
    public String getProfile() { return profile; }
    public String getSessionId() { return sessionId; }
    public int getSessionVersion() { return sessionVersion; }
    public String getIdentity() { return identity; }
    public String getDisplayName() { return displayName; }
    public String getEmail() { return email; }
    public boolean isTwoFactorEnabled() { return twoFactorEnabled; }
    public String getDepartmentOrCourse() { return departmentOrCourse; }
    public String getCampus() { return campus; }
    public String getSemester() { return semester; }
    public String getShift() { return shift; }

    public boolean isAdmin() {
        return "admin".equals(profile);
    }

    public boolean isDocenteOuAdmin() {
        return "docente".equals(profile) || "admin".equals(profile);
    }

    public boolean isAluno() {
        return "aluno".equals(profile);
    }
}
