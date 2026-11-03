// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package auth;

import core.RequisicaoHttp;
import core.RespostaHttp;
import videocall.VideoCallRoomHandler;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

// Teste sem bibliotecas do validador nativo JWT HS256 feito na unha.
public class JwtAuthValidatorTeste {
    private static final String SEGREDO_TESTE = "segredo-institucional-teste-minimo-32-chars!";
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    static boolean rejeita(String token, String segredo) {
        try {
            JwtAuthValidator.validarToken(token, segredo);
            return false;
        } catch (SecurityException e) {
            return true;
        }
    }

    public static int executar() {
        falhas = 0;

        // 1. Token valido de docente
        String tokenDocente = JwtAuthValidator.gerarTokenHs256(
                "507f1f77bcf86cd799439011",
                "docente",
                "sess-123",
                2,
                300L,
                SEGREDO_TESTE);
        UsuarioAutenticado docente = JwtAuthValidator.validarToken(tokenDocente, SEGREDO_TESTE);
        esperar("507f1f77bcf86cd799439011".equals(docente.getUserId())
                && "docente".equals(docente.getProfile())
                && docente.isDocenteOuAdmin()
                && !docente.isAdmin()
                && "sess-123".equals(docente.getSessionId())
                && docente.getSessionVersion() == 2,
                "JWT: valida assinatura HS256 e extrai claims do usuario logado");

        // 2. Rejeita segredo incorreto
        esperar(rejeita(tokenDocente, "outro-segredo-diferente-com-32-caracteres!"),
                "JWT: rejeita assinatura com segredo incorreto");

        // 3. Rejeita adulteracao de payload (tentativa de escalar aluno -> admin)
        String tokenAluno = JwtAuthValidator.gerarTokenHs256("u-aluno", "aluno", "sess-1", 0, 300L, SEGREDO_TESTE);
        String[] partes = tokenAluno.split("\\.");
        String payloadAdulterado = Base64.getUrlEncoder().withoutPadding().encodeToString(
                "{\"sub\":\"u-aluno\",\"profile\":\"admin\",\"exp\":4102444800}".getBytes(StandardCharsets.UTF_8));
        esperar(rejeita(partes[0] + "." + payloadAdulterado + "." + partes[2], SEGREDO_TESTE),
                "JWT: bloqueia escalacao de privilegio no payload");

        // 4. Rejeita ataque alg=none
        String headerNone = Base64.getUrlEncoder().withoutPadding().encodeToString(
                "{\"alg\":\"none\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        esperar(rejeita(headerNone + "." + partes[1] + ".assinatura", SEGREDO_TESTE),
                "JWT: bloqueia ataque de downgrade alg=none");

        // 5. Rejeita token expirado
        String tokenExpirado = JwtAuthValidator.gerarTokenHs256("u-exp", "aluno", "sess-exp", 0, -10L, SEGREDO_TESTE);
        esperar(rejeita(tokenExpirado, SEGREDO_TESTE),
                "JWT: rejeita token expirado");

        // 6. Rejeita perfil fora dos tres perfis institucionais
        String tokenPerfilInvalido = JwtAuthValidator.gerarTokenHs256("u-inv", "visitante", "sess-x", 0, 300L, SEGREDO_TESTE);
        esperar(rejeita(tokenPerfilInvalido, SEGREDO_TESTE),
                "JWT: rejeita perfil desconhecido");

        // 7. Integracao HTTP nativa: AuthSessionHandler e VideoCallRoomHandler com Bearer JWT
        String anterior = System.getProperty("AUTH_JWT_SECRET");
        try {
            System.setProperty("AUTH_JWT_SECRET", SEGREDO_TESTE);
            AuthSessionHandler sessionHandler = new AuthSessionHandler();
            VideoCallRoomHandler openHandler = new VideoCallRoomHandler();

            String respSemToken = executarHttp(sessionHandler, "GET /api/auth/session HTTP/1.1\r\nHost: localhost\r\n\r\n");
            esperar(respSemToken.startsWith("HTTP/1.1 401") && respSemToken.contains("\"authenticated\":false"),
                    "AuthSessionHandler: bloqueia requisicao sem Bearer (401)");

            String respComToken = executarHttp(
                    sessionHandler,
                    "GET /api/auth/session HTTP/1.1\r\nHost: localhost\r\nAuthorization: Bearer " + tokenDocente + "\r\n\r\n");
            esperar(respComToken.startsWith("HTTP/1.1 200")
                    && respComToken.contains("\"authenticated\":true")
                    && respComToken.contains("\"profile\":\"docente\""),
                    "AuthSessionHandler: valida sessao autenticada (200)");

            String corpoFalsificado = "roomCode=SALA-JWT-1&role=docente&name=Aluno+Tentando+Burlar";
            String reqAlunoTentandoAbrir = "POST /api/videocall/open HTTP/1.1\r\n"
                    + "Host: localhost\r\n"
                    + "Authorization: Bearer " + tokenAluno + "\r\n"
                    + "Content-Type: application/x-www-form-urlencoded\r\n"
                    + "Content-Length: " + corpoFalsificado.length() + "\r\n\r\n"
                    + corpoFalsificado;
            String respBloqueioAluno = executarHttp(openHandler, reqAlunoTentandoAbrir);
            esperar(respBloqueioAluno.startsWith("HTTP/1.1 403"),
                    "VideoCallRoomHandler: perfil do JWT prevalece sobre role falsificado no corpo (403)");

            String corpoDocente = "{\"roomCode\":\"SALA-JWT-1\",\"name\":\"Profa. Helena\"}";
            byte[] bytesDocente = corpoDocente.getBytes(StandardCharsets.UTF_8);
            String reqDocenteAbrindo = "POST /api/videocall/open HTTP/1.1\r\n"
                    + "Host: localhost\r\n"
                    + "Authorization: Bearer " + tokenDocente + "\r\n"
                    + "Content-Type: application/json\r\n"
                    + "Content-Length: " + bytesDocente.length + "\r\n\r\n"
                    + corpoDocente;
            String respSucessoDocente = executarHttp(openHandler, reqDocenteAbrindo);
            esperar(respSucessoDocente.startsWith("HTTP/1.1 200") && respSucessoDocente.contains("\"isOpen\":true"),
                    "VideoCallRoomHandler: docente autenticado abre sala com JSON e Bearer JWT (200)");
        } catch (Exception e) {
            esperar(false, "Integracao HTTP nativa sem excecoes: " + e.getMessage());
        } finally {
            if (anterior == null) {
                System.clearProperty("AUTH_JWT_SECRET");
            } else {
                System.setProperty("AUTH_JWT_SECRET", anterior);
            }
        }

        return falhas;
    }

    private static String executarHttp(core.ManipuladorHttp handler, String rawHttp) throws Exception {
        RequisicaoHttp req = RequisicaoHttp.ler(new ByteArrayInputStream(rawHttp.getBytes(StandardCharsets.UTF_8)));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        RespostaHttp resp = new RespostaHttp(out);
        handler.handle(req, resp);
        return new String(out.toByteArray(), StandardCharsets.UTF_8);
    }

    public static void main(String[] args) {
        int erros = executar();
        if (erros > 0) {
            System.out.println(erros + " falha(s)");
            System.exit(1);
        }
        System.out.println("Todos os testes passaram");
    }
}
