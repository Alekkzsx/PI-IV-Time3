// Desenvolvido por Marcelo Zarpelon

package docente;

import database.BancoMemoria;

import java.util.Map;

// Teste sem bibliotecas: o seed valida contra os esquemas e pode rodar varias vezes sem duplicar.
public class SeedDocenteTeste {
    private static int falhas = 0;

    static void esperar(boolean condicao, String nome) {
        System.out.println((condicao ? "[OK]    " : "[FALHA] ") + nome);
        if (!condicao) falhas++;
    }

    public static void main(String[] args) {
        BancoMemoria banco = new BancoMemoria();
        int primeira = SeedDocente.popular(banco);
        int segunda = SeedDocente.popular(banco);
        esperar(primeira == 13 && segunda == 13, "grava 13 documentos nas duas execucoes");
        esperar(banco.colecao(DocenteEsquemas.CURSOS).listar(Map.of()).size() == 3, "3 cursos, sem duplicar na segunda execucao");
        esperar(banco.colecao(DocenteEsquemas.CURSOS).listar(Map.of("professorIdentity", SeedDocente.DOCENTE)).size() == 3, "cursos ligados ao docente");
        esperar(banco.colecao(DocenteEsquemas.TAREFAS).listar(Map.of("classCode", "APS2-4N")).size() == 1, "tarefa ligada ao curso");
        esperar(banco.colecao(DocenteEsquemas.DOCENTES).buscar(SeedDocente.DOCENTE) != null, "perfil do docente existe");
        if (falhas > 0) { System.out.println(falhas + " falha(s)"); System.exit(1); }
        System.out.println("Todos os testes passaram");
    }
}
