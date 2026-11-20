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
    private final int sessionVersion;
    private final String identity;
    private final String displayName;
    private final String email;
    private final boolean twoFactorEnabled;
    private final String departmentOrCourse;
    private final String campus;
    private final String semester;
    private final String shift;
    private final boolean requirePasswordChange;
    private final String socialName;
    private final String personalEmail;
    private final String phone;
    private final String biography;
    private final Map<String, Object> preferences;

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
    public boolean isRequirePasswordChange() { return requirePasswordChange; }
    public String getSocialName() { return socialName; }
    public String getPersonalEmail() { return personalEmail; }
    public String getPhone() { return phone; }
    public String getBiography() { return biography; }
    public Map<String, Object> getPreferences() { return preferences; }

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
