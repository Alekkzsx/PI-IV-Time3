// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart'; // Importa o pacote principal de componentes visuais do Material Design para Flutter

// Declaração da tela como um Stateless Widget (componente estático que não altera estado interno diretamente)
class UsersPage extends StatelessWidget {
  const UsersPage({Key? key}) : super(key: key); // Construtor padrão com suporte a chave (key)

  @override
  Widget build(BuildContext context) {
    // Lista local de mapas contendo dados fictícios de usuários do sistema acadêmico
    final List<Map<String, String>> usuarios = [
      {'id': '2024.1.00892', 'nome': 'Gabriel Soares de Oliveira', 'email': 'gabriel.oliveira@aluno.universidade.edu.br', 'perfil': 'Discente', 'curso': 'Engenharia de Software (5º Semestre)', 'status': 'Ativo'},
      {'id': 'DOC-88410', 'nome': 'Profa. Dra. Helena Bittencourt', 'email': 'helena.bittencourt@docente.universidade.edu.br', 'perfil': 'Docente', 'curso': 'Departamento de Computação e Sistemas', 'status': 'Ativo'},
      {'id': 'ADM-00129', 'nome': 'Carlos Eduardo Mendes', 'email': 'carlos.mendes@secretaria.universidade.edu.br', 'perfil': 'Administrador', 'curso': 'Secretaria Geral Acadêmica & Auditoria', 'status': 'Ativo'},
    ];

    // Widget que permite a rolagem da tela inteira caso o conteúdo ultrapasse a altura da janela
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0), // Adiciona um espaçamento interno de 32 pixels em todas as bordas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha os filhos horizontalmente à esquerda
        children: [
          // Rótulo superior pequeno indicando o contexto da seção
          const Text('Usuários', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8), // Espaçamento vertical entre os textos
          
          // Linha de cabeçalho contendo o título principal/descrição e o botão de ação principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui os itens nas extremidades (esquerda e direita)
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Alinha os textos do cabeçalho à esquerda
                children: [
                  Text('Gestão de Usuários & Controle de Acessos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Emissão de registros acadêmicos (R.A.), matrículas funcionais e governança de credenciais.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              // Botão elevado com ícone para adicionar um novo cadastro institucional
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), // Estilização com fundo preto e texto/ícone branco
                onPressed: () {}, // Ação ao clicar (atualmente vazia)
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Cadastro Institucional'),
              ),
            ],
          ),
          const SizedBox(height: 24), // Espaçamento antes da lista de usuários
          
          // Container estilizado para agrupar a lista em formato de cartão com bordas arredondadas e sutis
          Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: Colors.grey[200]!)
            ),
            // Constrói uma lista dinâmica baseada na quantidade de itens da lista 'usuarios'
            child: ListView.separated(
              shrinkWrap: true, // Faz com que a lista ocupe apenas o espaço necessário de seus elementos (evita conflito com o SingleChildScrollView)
              physics: const NeverScrollableScrollPhysics(), // Desativa a rolagem própria da lista, delegando-a inteiramente ao SingleChildScrollView pai
              itemCount: usuarios.length, // Número total de itens (3)
              separatorBuilder: (_, __) => const Divider(height: 1), // Linha divisória de 1 pixel entre cada elemento da lista
              itemBuilder: (context, index) {
                final u = usuarios[index]; // Recupera o usuário correspondente ao índice atual
                
                // Exibe cada usuário utilizando o componente padrão ListTile
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Espaçamento interno do item
                  title: Text(u['nome']!, style: const TextStyle(fontWeight: FontWeight.bold)), // Nome do usuário em negrito
                  subtitle: Text('${u['id']}\n${u['email']}'), // Subtítulo contendo o ID/R.A. e o e-mail em linhas separadas
                  
                  // Seção à direita (trailing) contendo uma tag de perfil e um botão de ação
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Ajusta o tamanho da linha para o espaço mínimo ocupado pelos filhos
                    children: [
                      Chip(label: Text(u['perfil']!)), // Etiqueta (Chip) destacando o perfil do usuário (Discente, Docente, etc.)
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: () {}, child: const Text('Reset Senha')), // Botão secundário para redefinir a senha
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}