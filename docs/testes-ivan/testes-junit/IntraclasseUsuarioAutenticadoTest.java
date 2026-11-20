// Desenvolvido por Time 3 AGMRM — PI-IV (PUC-Campinas 2026)
// Equipe: Alex Gabriel (24802449), Guilherme Moreira (25006702),
//         Marcelo Zarpelon (25015323), Murillo Caravita (25014012), Rafael Inacio (25009719)

import auth.model.UsuarioAutenticado;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Teste Unitario INTRACLASSE — Classe de Dominio: {@link UsuarioAutenticado}.
 *
 * Abordagem de Particionamento Adotada: PARTICIONAMENTO POR ATRIBUTOS.
 * Justificativa: Entidade imutavel de dominio sem maquina de estados nem calculos complexos;
 * mantem os 18 atributos da identidade autenticada organizados em 4 grupos de atributos.
 */
@DisplayName("Intraclasse [ATRIBUTOS] — UsuarioAutenticado")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class IntraclasseUsuarioAutenticadoTest {

    @Test
    @Order(1)
    @DisplayName("Grupo A [IDENTIDADE & RBAC]: Normaliza profile (trim/lowercase) e avalia predicados RBAC")
    void grupoAIdentidadeENormalizacaoPerfilRbac() {
        UsuarioAutenticado admin = new UsuarioAutenticado(
                "65f001", "  ADMIN  ", "jti-1", 2, "admin@agmrm.edu", "Administrador");
        assertEquals("admin", admin.getProfile(), "Profile deve ser normalizado para minusculo sem espacos");
        assertTrue(admin.isAdmin());
        assertTrue(admin.isDocenteOuAdmin());
        assertFalse(admin.isAluno());

        UsuarioAutenticado docente = new UsuarioAutenticado(
                "65f002", "Docente", "jti-2", 1, "prof@agmrm.edu", "Prof. Renata");
        assertEquals("docente", docente.getProfile());
        assertFalse(docente.isAdmin());
        assertTrue(docente.isDocenteOuAdmin());
        assertFalse(docente.isAluno());

        UsuarioAutenticado aluno = new UsuarioAutenticado(
                "65f003", " ALUNO ", "jti-3", 1, "24802449", "Alex Gabriel");
        assertEquals("aluno", aluno.getProfile());
        assertFalse(aluno.isAdmin());
        assertFalse(aluno.isDocenteOuAdmin());
        assertTrue(aluno.isAluno());

        UsuarioAutenticado desconhecido = new UsuarioAutenticado(
                "65f004", "visitante", "jti-4", 1, "vis", "Visitante");
        assertFalse(desconhecido.isAdmin());
        assertFalse(desconhecido.isDocenteOuAdmin());
        assertFalse(desconhecido.isAluno());
    }

    @Test
    @Order(2)
    @DisplayName("Grupo B [SESSAO & SEGURANCA]: Preserva sessionId, sessionVersion, 2FA e requirePasswordChange")
    void grupoBSessaoEFlagsSeguranca() {
        UsuarioAutenticado usuario = new UsuarioAutenticado(
                "65f010", "docente", "sessao-uuid-99", 5,
                "doc01", "Prof. Teste", "doc01@puc.edu",
                true, "Engenharia de Software", "Campus I", "2026/2", "Noturno",
                true, "Prof. Social", "pessoal@mail.com", "19999990000", "Docente titular", null);

        assertEquals("sessao-uuid-99", usuario.getSessionId());
        assertEquals(5, usuario.getSessionVersion());
        assertTrue(usuario.isTwoFactorEnabled());
        assertTrue(usuario.isRequirePasswordChange());
        assertEquals("doc01@puc.edu", usuario.getEmail());
    }

    @Test
    @Order(3)
    @DisplayName("Grupo C [ACADEMICO & IMUTABILIDADE]: Copia defensiva e mapa imutavel de preferences")
    void grupoCDadosAcademicosEImutabilidadePreferences() {
        Map<String, Object> entrada = new HashMap<String, Object>();
        entrada.put("theme", "dark");
        entrada.put("fontSize", Integer.valueOf(14));

        UsuarioAutenticado usuario = new UsuarioAutenticado(
                "65f020", "aluno", "sess-1", 1,
                "25014012", "Murillo Caravita", "murillo@puc.edu",
                false, "Engenharia de Software", "Campus I", "4o Semestre", "Matutino",
                false, "Murillo", "murillo.pessoal@mail.com", "19988887777", "Estudante PI-IV", entrada);

        assertEquals("Engenharia de Software", usuario.getDepartmentOrCourse());
        assertEquals("Campus I", usuario.getCampus());
        assertEquals("4o Semestre", usuario.getSemester());
        assertEquals("Matutino", usuario.getShift());
        assertEquals("Murillo", usuario.getSocialName());
        assertEquals("murillo.pessoal@mail.com", usuario.getPersonalEmail());
        assertEquals("19988887777", usuario.getPhone());
        assertEquals("Estudante PI-IV", usuario.getBiography());

        entrada.put("theme", "comprometido");
        assertEquals("dark", usuario.getPreferences().get("theme"),
                "Copia defensiva deve isolar o mapa interno contra mutacoes externas");

        assertThrows(UnsupportedOperationException.class,
                () -> usuario.getPreferences().put("injetado", Boolean.TRUE),
                "getPreferences() deve retornar mapa estritamente imutavel");
    }

    @Test
    @Order(4)
    @DisplayName("Grupo D [CONSTRUTORES & ANOMALIA #1]: Sobrecargas 12/8/6 campos e evidencia de userId null")
    void grupoDSobrecargasNullSafetyEAnomaliaUserId() {
        UsuarioAutenticado c12 = new UsuarioAutenticado(
                "id12", "aluno", "s12", 1, "25009719", "Rafael",
                "rafael@puc.edu", false, "ES", "Campus I", "4", "Noturno");
        assertEquals("ES", c12.getDepartmentOrCourse());
        assertFalse(c12.isRequirePasswordChange());
        assertTrue(c12.getPreferences().isEmpty());

        UsuarioAutenticado c8 = new UsuarioAutenticado(
                "id8", "docente", "s8", 2, "doc8", "Docente 8", "d8@puc.edu", true);
        assertTrue(c8.isTwoFactorEnabled());
        assertEquals("", c8.getCampus());

        UsuarioAutenticado comNulls = new UsuarioAutenticado(
                null, null, null, 0, null, null, null, false,
                null, null, null, null, false, null, null, null, null, null);
        assertEquals("", comNulls.getProfile());
        assertEquals("", comNulls.getSessionId());
        assertEquals("", comNulls.getIdentity());
        assertEquals("", comNulls.getDisplayName());
        assertEquals("", comNulls.getEmail());
        assertNotNull(comNulls.getPreferences());

        assertNull(comNulls.getUserId(),
                "Evidencia da Anomalia #1: getUserId() retorna null, divergindo do contrato do Javadoc");
    }
}
