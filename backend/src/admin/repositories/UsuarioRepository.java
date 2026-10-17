// Desenvolvido por Guilherme Henrique Moreira

package admin.repositories;

import models.Usuario;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

// Armazena usuarios em arquivo local nesta primeira fase.
public class UsuarioRepository {
    private final Map<String, Usuario> usuarios = new LinkedHashMap<>();
    private final Path arquivo;

    public UsuarioRepository(Path arquivo) throws IOException {
        this.arquivo = arquivo;
        if (Files.exists(arquivo)) carregar();
    }

    private String codificar(String texto) {
        return Base64.getEncoder().encodeToString(texto.getBytes(StandardCharsets.UTF_8));
    }

    private String decodificar(String texto) {
        return new String(Base64.getDecoder().decode(texto), StandardCharsets.UTF_8);
    }

    private void carregar() throws IOException {
        for (String linha : Files.readAllLines(arquivo, StandardCharsets.UTF_8)) {
            if (linha.isBlank()) continue;
            String[] partes = linha.split("\\|", -1);
            if (partes.length != 6) throw new IOException("Arquivo de usuarios invalido");
            Usuario u = new Usuario(decodificar(partes[0]), decodificar(partes[1]),
                    decodificar(partes[2]), decodificar(partes[3]), decodificar(partes[4]), decodificar(partes[5]));
            usuarios.put(u.id, u);
        }
    }

    private void salvar() throws IOException {
        Files.createDirectories(arquivo.toAbsolutePath().getParent());
        List<String> linhas = new ArrayList<>();
        for (Usuario u : usuarios.values()) {
            linhas.add(String.join("|", codificar(u.id), codificar(u.nome), codificar(u.email),
                    codificar(u.perfil), codificar(u.curso), codificar(u.status)));
        }
        Path temporario = Files.createTempFile(arquivo.toAbsolutePath().getParent(), "usuarios-", ".tmp");
        try {
            Files.write(temporario, linhas, StandardCharsets.UTF_8);
            try { Files.move(temporario, arquivo, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE); }
            catch (java.nio.file.AtomicMoveNotSupportedException e) {
                Files.move(temporario, arquivo, StandardCopyOption.REPLACE_EXISTING);
            }
        } finally { Files.deleteIfExists(temporario); }
    }

    public synchronized List<Usuario> listar() { return new ArrayList<>(usuarios.values()); }
    public synchronized Usuario buscar(String id) { return usuarios.get(id); }
    public synchronized boolean existeEmail(String email, String ignorarId) {
        for (Usuario u : usuarios.values()) {
            if (u.email.equalsIgnoreCase(email) && !u.id.equals(ignorarId)) return true;
        }
        return false;
    }
    public synchronized void gravar(Usuario usuario) throws IOException {
        Usuario antigo = usuarios.put(usuario.id, usuario);
        try { salvar(); }
        catch (IOException e) {
            if (antigo == null) usuarios.remove(usuario.id); else usuarios.put(usuario.id, antigo);
            throw e;
        }
    }
}
