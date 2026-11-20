// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

import auth.model.UsuarioAutenticado;
import auth.modules.persistencia.RepositorioUsuarios;
import bridge.ClientePonteAcademica;
import core.RespostaHttp;
import org.bson.types.ObjectId;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Classe abstrata base para endpoints administrativos de gestao de identidades (/api/admin/*).
 * Garante perfil admin, injeta ClientePonteAcademica e centraliza validacao de write-guard e IDs.
 */
public abstract class AdminHandlerAbstrato extends HandlerAutenticadoAbstrato {
    // Whitelist de perfis atribuiveis via admin: qualquer valor fora daqui e rejeitado no CRUD.
    protected static final Set<String> PERFIS_PERMITIDOS = Collections.unmodifiableSet(
            new HashSet<String>(Arrays.asList("aluno", "docente", "admin")));

    protected final ClientePonteAcademica ponte;

    /** @param ponte cliente da ponte academica (:3001); null cria um proprio (conveniencia de testes). */
    protected AdminHandlerAbstrato(RepositorioUsuarios repositorio, ClientePonteAcademica ponte) {
        super(repositorio);
        this.ponte = ponte != null ? ponte : new ClientePonteAcademica();
    }

    /** final: nenhuma subclasse administrativa pode afrouxar a exigencia de perfil admin. */
    @Override
    protected final boolean exigirAdmin() {
        return true;
    }

    @Override
    protected String tagLog() {
        return "ADMIN-USERS";
    }

    /**
     * Valida o write-guard atomico garantindo que o administrador continua ativo antes de mutacoes.
     * Reconfere no banco no momento da escrita (fecha a janela TOCTOU entre o JWT validar
     * e a mutacao acontecer: admin rebaixado/desativado no meio do caminho perde o acesso).
     *
     * @return true se pode escrever; false ja responde 403 e o handler deve abortar
     */
    protected boolean exigirEscritaAdmin(UsuarioAutenticado admin, RespostaHttp resposta) throws IOException {
        if (!repositorio.registrarEscritaAdmin(admin.getUserId())) {
            responderErro(resposta, 403, "forbidden", "Acesso administrativo revogado.");
            return false;
        }
        return true;
    }

    /**
     * Extrai segmentos apos "/api/admin/users/" validando o ObjectId do primeiro segmento.
     * Ex.: "/api/admin/users/665f.../security" -> ["665f...", "security"].
     *
     * @return segmentos com o id normalizado, ou null se o id for invalido (400 ja respondido)
     */
    protected String[] extrairSegmentosUsuario(String caminho, RespostaHttp resposta) throws IOException {
        String resto = caminho.substring("/api/admin/users/".length());
        String[] partes = resto.split("/");
        String userId = partes.length >= 1 ? partes[0].trim() : "";
        if (!ObjectId.isValid(userId)) {
            responderErro(resposta, 400, "invalid_id", "Identificador invalido.");
            return null;
        }
        partes[0] = userId;
        return partes;
    }
}
