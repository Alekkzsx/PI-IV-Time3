// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import utils.ConfigEnv;

import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Limitador de tentativas de login implementado 100% em memoria com ConcurrentHashMap.
 * Protege contra ataques de forca bruta aplicando bloqueios temporarios.
 *
 * Regras (configuraveis via .env):
 * - MAX_FAILED_LOGIN_ATTEMPTS: maximo de tentativas falhas antes do bloqueio (padrao: 5)
 * - LOCKOUT_DURATION_SECONDS: duracao do bloqueio em segundos (padrao: 30)
 *
 * Janelas de bloqueio progressivo:
 * - Nivel 1 (5 falhas em 5 min): bloqueio de 30 segundos
 * - Nivel 2 (15 falhas em 15 min): bloqueio de 5 minutos
 * - Nivel 3 (30 falhas em 30 min): bloqueio de 30 minutos
 *
 * A identidade do atacante e composta por IP + usuario para maior granularidade.
 */
public final class LimitadorTentativas {

    private static final LimitadorTentativas INSTANCIA = new LimitadorTentativas();

    private final ConcurrentHashMap<String, RegistroTentativas> tentativas =
            new ConcurrentHashMap<String, RegistroTentativas>();

    private volatile long ultimaLimpeza = System.currentTimeMillis();
    private static final long INTERVALO_LIMPEZA_MS = 120_000; // 2 minutos

    private LimitadorTentativas() {}

    public static LimitadorTentativas getInstance() {
        return INSTANCIA;
    }

    /**
     * Verifica se a tentativa de login deve ser permitida.
     *
     * @param identidade Identidade do usuario (ex: email ou matricula).
     * @param ip         Endereco IP do cliente.
     * @return true se permitido, false se bloqueado.
     */
    public boolean permitirTentativa(String identidade, String ip) {
        limparExpiradosSeNecessario();

        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        // Verificar bloqueio por usuario
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null && regUsuario.estaBloqueado()) {
            return false;
        }

        // Verificar bloqueio por IP
        RegistroTentativas regIp = tentativas.get(chaveIp);
        if (regIp != null && regIp.estaBloqueado()) {
            return false;
        }

        return true;
    }

    /**
     * Registra uma tentativa de login falha.
     *
     * @param identidade Identidade do usuario.
     * @param ip         Endereco IP do cliente.
     * @return Mensagem descritiva do estado (ex: "bloqueado por 30s", "3/5 tentativas").
     */
    public String registrarFalha(String identidade, String ip) {
        int maxTentativas = ConfigEnv.obterInteiro("MAX_FAILED_LOGIN_ATTEMPTS", 5);
        long lockoutMs = (long) ConfigEnv.obterInteiro("LOCKOUT_DURATION_SECONDS", 30) * 1000L;

        String chaveUsuario = "user:" + normalizar(identidade);
        String chaveIp = "ip:" + normalizar(ip);

        RegistroTentativas regUsuario = tentativas.computeIfAbsent(chaveUsuario,
                k -> new RegistroTentativas());
        RegistroTentativas regIp = tentativas.computeIfAbsent(chaveIp,
                k -> new RegistroTentativas());

        int falhasUsuario = regUsuario.registrarFalha(maxTentativas, lockoutMs);
        regIp.registrarFalha(maxTentativas * 3, lockoutMs * 5); // IP tolera mais falhas

        // Bloqueio progressivo
        if (falhasUsuario >= maxTentativas * 6) {
            // Nivel 3: bloqueio longo
            regUsuario.aplicarBloqueio(lockoutMs * 60); // 30x o lockout base
            return "Bloqueado por 30 minutos devido a excesso de tentativas.";
        } else if (falhasUsuario >= maxTentativas * 3) {
            // Nivel 2: bloqueio medio
            regUsuario.aplicarBloqueio(lockoutMs * 10); // 5x o lockout base
            return "Bloqueado por 5 minutos devido a excesso de tentativas.";
        } else if (falhasUsuario >= maxTentativas) {
            // Nivel 1: bloqueio curto
            regUsuario.aplicarBloqueio(lockoutMs);
            long segundosRestantes = lockoutMs / 1000;
            return "Bloqueado por " + segundosRestantes + " segundos. Tente novamente depois.";
        }

        return "Credenciais invalidas. Tentativa " + falhasUsuario + " de " + maxTentativas + ".";
    }

    /**
     * Registra um login bem-sucedido, resetando o contador de falhas.
     *
     * @param identidade Identidade do usuario.
     * @param ip         Endereco IP do cliente.
     */
    public void registrarSucesso(String identidade, String ip) {
        String chaveUsuario = "user:" + normalizar(identidade);
        RegistroTentativas regUsuario = tentativas.get(chaveUsuario);
        if (regUsuario != null) {
            regUsuario.resetar();
        }
    }

    /**
     * Retorna quantos segundos de bloqueio restam para a identidade.
     */
    public long segundosRestantesBloqueio(String identidade) {
        String chave = "user:" + normalizar(identidade);
        RegistroTentativas reg = tentativas.get(chave);
        if (reg == null) return 0;
        long ms = reg.milissegundosRestantesBloqueio();
        return ms > 0 ? (ms / 1000) + 1 : 0;
    }

    private void limparExpiradosSeNecessario() {
        long agora = System.currentTimeMillis();
        if (agora - ultimaLimpeza < INTERVALO_LIMPEZA_MS) {
            return;
        }
        ultimaLimpeza = agora;

        Iterator<Map.Entry<String, RegistroTentativas>> iterador =
                tentativas.entrySet().iterator();
        while (iterador.hasNext()) {
            Map.Entry<String, RegistroTentativas> entrada = iterador.next();
            if (entrada.getValue().estaExpirado()) {
                iterador.remove();
            }
        }
    }

    private String normalizar(String valor) {
        if (valor == null) return "unknown";
        String limpo = valor.trim().toLowerCase();
        return limpo.isEmpty() ? "unknown" : limpo;
    }

    /**
     * Limpa todos os registros (para testes).
     */
    public void limparTudo() {
        tentativas.clear();
    }

    /**
     * Registro interno de tentativas por identidade.
     */
    private static final class RegistroTentativas {
        private final AtomicInteger contadorFalhas = new AtomicInteger(0);
        private volatile long bloqueadoAteMs = 0;
        private volatile long primeiraFalhaMs = 0;
        private volatile long ultimaFalhaMs = 0;
        private static final long JANELA_FALHAS_MS = 300_000; // 5 minutos

        synchronized int registrarFalha(int maxTentativas, long lockoutMs) {
            long agora = System.currentTimeMillis();

            // Se a primeira falha ja esta fora da janela, resetar
            if (primeiraFalhaMs > 0 && (agora - primeiraFalhaMs) > JANELA_FALHAS_MS) {
                contadorFalhas.set(0);
                primeiraFalhaMs = agora;
            }

            if (primeiraFalhaMs == 0) {
                primeiraFalhaMs = agora;
            }
            ultimaFalhaMs = agora;

            int total = contadorFalhas.incrementAndGet();
            return total;
        }

        synchronized void aplicarBloqueio(long duracaoMs) {
            bloqueadoAteMs = System.currentTimeMillis() + duracaoMs;
        }

        synchronized void resetar() {
            contadorFalhas.set(0);
            bloqueadoAteMs = 0;
            primeiraFalhaMs = 0;
            ultimaFalhaMs = 0;
        }

        boolean estaBloqueado() {
            if (bloqueadoAteMs <= 0) return false;
            if (System.currentTimeMillis() > bloqueadoAteMs) {
                bloqueadoAteMs = 0;
                contadorFalhas.set(0);
                return false;
            }
            return true;
        }

        long milissegundosRestantesBloqueio() {
            if (bloqueadoAteMs <= 0) return 0;
            long diff = bloqueadoAteMs - System.currentTimeMillis();
            return diff > 0 ? diff : 0;
        }

        boolean estaExpirado() {
            if (bloqueadoAteMs > 0 && System.currentTimeMillis() <= bloqueadoAteMs) {
                return false; // Ainda bloqueado, nao expirar
            }
            if (primeiraFalhaMs <= 0) return true;
            return (System.currentTimeMillis() - ultimaFalhaMs) > 600_000; // 10 min inativo
        }
    }
}
