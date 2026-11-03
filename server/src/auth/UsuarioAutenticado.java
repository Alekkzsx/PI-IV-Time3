// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import java.util.Locale;

/**
 * Representa a identidade autenticada extraida do token de login institucional (JWT HS256)
 * ou da conferencia direta com o servico de sessao.
 */
public final class UsuarioAutenticado {
    private final String userId;
    private final String profile;
    private final String sessionId;
    private final int sessionVersion;
    private final String identity;
    private final String displayName;

    public UsuarioAutenticado(
            String userId,
            String profile,
            String sessionId,
            int sessionVersion,
            String identity,
            String displayName) {
        this.userId = userId;
        this.profile = profile != null ? profile.trim().toLowerCase(Locale.ROOT) : "";
        this.sessionId = sessionId != null ? sessionId : "";
        this.sessionVersion = sessionVersion;
        this.identity = identity != null ? identity : "";
        this.displayName = displayName != null ? displayName : "";
    }

    public String getUserId() { return userId; }
    public String getProfile() { return profile; }
    public String getSessionId() { return sessionId; }
    public int getSessionVersion() { return sessionVersion; }
    public String getIdentity() { return identity; }
    public String getDisplayName() { return displayName; }

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

