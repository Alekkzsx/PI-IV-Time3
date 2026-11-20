// Desenvolvido por Marcelo Zarpelon - RA: 25015323
package auth.modules.admin;

import auth.abstratas.AdminHandlerAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import auth.modules.persistencia.RepositorioUsuarios;
import auth.utils.SenhaHasher;
import bridge.ClientePonteAcademica;
import com.mongodb.MongoWriteException;
import core.RequisicaoHttp;
import core.RespostaHttp;
import org.bson.Document;

import java.security.SecureRandom;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Handler administrativo para provisionamento rapido de docentes com identidade DOC-XXXXXXXX e senha temporaria.
 * Rota: POST /api/admin/teachers
 */
public class AdminTeacherHandler extends AdminHandlerAbstrato {
    private static final SecureRandom RANDOM = new SecureRandom();

    public AdminTeacherHandler(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio, ponte);
    }

    @Override
    protected String metodoPermitido() {
        return "POST";
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Metodo nao permitido neste servidor.";
    }

    /**
     * Provisiona um docente em uma chamada: valida dados -> e-mail unico ->
     * identidade DOC-XXXXXXXX aleatoria + senha temporaria -> insere com
     * requirePasswordChange=true (troca obrigatoria no primeiro login) ->
     * audita + envia boas-vindas com as credenciais -> 201.
     */
    @Override
    protected void processarAutenticado(
            RequisicaoHttp req, RespostaHttp resp, UsuarioAutenticado admin) throws Exception {
        Map<String, Object> body = lerJsonObjeto(req);
        String name = getPrimeiroTexto(body, "name", "displayName");
        String email = getString(body, "email");
        String department = getPrimeiroTexto(body, "department", "departmentOrCourse");

        if (name == null || name.length() < 2 || email == null || !email.contains("@")
                || department == null || department.length() < 2) {
            responderErro(resp, 400, "invalid_request", "Dados do docente invalidos.");
            return;
        }
        String normalizedEmail = email.toLowerCase(Locale.ROOT);
        if (repositorio.existeEmail(normalizedEmail)) {
            responderErro(resp, 409, "email_exists", "Ja existe uma conta com esse e-mail.");
            return;
        }

        String identity = gerarIdentidadeDocente();
        // Senha temporaria Agmrm@NNNNNN: ja atende a politica (maiuscula/minuscula/digito/especial)
        // e e descartada no primeiro login pelo requirePasswordChange.
        String tempPassword = String.format("Agmrm@%06d", RANDOM.nextInt(1_000_000));
        Date agora = new Date();
        Document teacher = new Document()
                .append("identity", identity)
                .append("normalizedIdentity", identity.toLowerCase(Locale.ROOT))
                .append("email", normalizedEmail)
                .append("normalizedEmail", normalizedEmail)
                .append("displayName", name)
                .append("profile", "docente")
                .append("passwordHash", SenhaHasher.hash(tempPassword))
                .append("active", Boolean.TRUE)
                .append("sessionVersion", Integer.valueOf(0))
                .append("requirePasswordChange", Boolean.TRUE)
                .append("twoFactorRequired", Boolean.FALSE)
                .append("twoFactorEnabled", Boolean.FALSE)
                .append("department", department)
                .append("departmentOrCourse", department)
                .append("createdBy", admin.getUserId())
                .append("createdAt", agora)
                .append("updatedAt", agora);

        try {
            repositorio.inserirDocumentoUsuario(teacher);
        } catch (MongoWriteException e) {
            // Colisao de indice unico (identidade/e-mail): 409 em vez de 500 - basta tentar de novo.
            responderErro(resp, 409, "identity_exists", "Nao foi possivel gerar uma identidade unica. Tente novamente.");
            return;
        }

        repositorio.registrarAuditoria(admin.getUserId(), "teacher_created", teacher.getObjectId("_id").toHexString(), null);
        SmtpCliente.enviarBoasVindasComResultado(normalizedEmail, name, identity, "docente", tempPassword)
                .whenComplete((resultado, erro) -> repositorio.registrarResultadoEnvioEmail(
                        admin.getUserId(), "admin_teacher_welcome_email", normalizedEmail, resultado, erro));

        Map<String, Object> result = new LinkedHashMap<String, Object>();
        result.put("identity", identity);
        result.put("name", name);
        result.put("email", normalizedEmail);
        result.put("department", department);
        result.put("profile", "docente");
        enviarJson(resp, 201, result);
    }

    /** Identidade docente: prefixo DOC- + 10 hex de 5 bytes aleatorios (40 bits anti-colisao). */
    private static String gerarIdentidadeDocente() {
        byte[] idBytes = new byte[5];
        RANDOM.nextBytes(idBytes);
        StringBuilder hex = new StringBuilder("DOC-");
        for (byte b : idBytes) {
            hex.append(String.format("%02X", b & 0xff));
        }
        return hex.toString();
    }
}
