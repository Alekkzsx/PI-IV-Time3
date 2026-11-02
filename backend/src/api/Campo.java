// Desenvolvido por Marcelo Zarpelon

package api;

import java.util.List;

// Descricao de um campo de documento: nome, tipo, obrigatoriedade e limite de tamanho.
public final class Campo {
    public enum Tipo { TEXTO, INTEIRO, DECIMAL, BOOLEANO, LISTA, OPCAO }

    public final String nome;
    public final Tipo tipo;
    public final boolean obrigatorio;
    // Para TEXTO: maximo de caracteres; para LISTA: maximo de itens.
    public final int limite;
    // Para OPCAO: valores permitidos.
    public final List<String> valores;

    private Campo(String nome, Tipo tipo, boolean obrigatorio, int limite, List<String> valores) {
        this.nome = nome;
        this.tipo = tipo;
        this.obrigatorio = obrigatorio;
        this.limite = limite;
        this.valores = valores;
    }

    private Campo(String nome, Tipo tipo, boolean obrigatorio, int limite) {
        this(nome, tipo, obrigatorio, limite, List.of());
    }

    public static Campo texto(String nome, boolean obrigatorio, int limite) { return new Campo(nome, Tipo.TEXTO, obrigatorio, limite); }
    public static Campo inteiro(String nome, boolean obrigatorio) { return new Campo(nome, Tipo.INTEIRO, obrigatorio, 0); }
    public static Campo decimal(String nome, boolean obrigatorio) { return new Campo(nome, Tipo.DECIMAL, obrigatorio, 0); }
    public static Campo booleano(String nome, boolean obrigatorio) { return new Campo(nome, Tipo.BOOLEANO, obrigatorio, 0); }
    public static Campo opcao(String nome, boolean obrigatorio, String... valores) { return new Campo(nome, Tipo.OPCAO, obrigatorio, 0, List.of(valores)); }
    public static Campo lista(String nome, boolean obrigatorio, int limite) { return new Campo(nome, Tipo.LISTA, obrigatorio, limite); }
}
