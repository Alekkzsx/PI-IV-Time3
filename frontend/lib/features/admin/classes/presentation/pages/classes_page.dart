// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart'; // Importa o pacote principal do Material Design para Flutter

// Declaração da tela de Turmas como um StatelessWidget (componente estático sem estado interno complexo)
class ClassesPage extends StatelessWidget {
  const ClassesPage({Key? key}) : super(key: key); // Construtor padrão com suporte a chave (key)

  @override
  Widget build(BuildContext context) {
    // Componente que permite a rolagem da página inteira caso o conteúdo exceda a altura da tela
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0), // Margem interna de 32 pixels em toda a volta do conteúdo principal
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha todos os elementos filhos à esquerda
        children: [
          // Rótulo de contexto superior indicando a seção atual
          const Text('Turmas', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8), // Espaçamento vertical
          
          // Título principal da página de gestão de turmas e ensalamento
          const Text('Gestão de Turmas, Ensalamento & Atribuição Docente', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), // Pequeno espaçamento vertical
          
          // Subtítulo descritivo detalhando o propósito funcional da tela
          const Text('Abertura de turmas no período letivo, alocação de salas/laboratórios e vinculação do professor regente.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24), // Espaçamento antes de exibir a tabela de dados
          
          // Container estilizado para envolver a tabela, dando aspecto de cartão (card) com borda arredondada e sutil
          Container(
            padding: const EdgeInsets.all(16), // Espaçamento interno dentro do container da tabela
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas de 12 pixels
              border: Border.all(color: Colors.grey[200]!) // Borda cinza bem clara para destaque sutil
            ),
            // Widget de Tabela estruturada (DataTable) para exibição de dados tabulares
            child: DataTable(
              // Definição das colunas da tabela acadêmica
              columns: const [
                DataColumn(label: Text('CÓDIGO / DISCIPLINA')),
                DataColumn(label: Text('CURSO & TURNO')),
                DataColumn(label: Text('LOCAL')),
                DataColumn(label: Text('VAGAS')),
                DataColumn(label: Text('DOCENTE')),
                DataColumn(label: Text('AÇÕES')),
              ],
              // Linhas de dados contidas na tabela
              rows: [
                DataRow(cells: [
                  // Célula 1: Nome da disciplina e código correspondente em duas linhas
                  const DataCell(Text('Análise e Projeto de Sistemas II\n218131 - APS-II')),
                  
                  // Célula 2: Curso, período letivo (2026/2) e turno (Noturno)
                  const DataCell(Text('Engenharia de Software\n2026/2 • Noturno')),
                  
                  // Célula 3: Local físico da aula (Laboratório e Bloco)
                  const DataCell(Text('Lab Informática 04 - Bloco C')),
                  
                  // Célula 4: Contagem de vagas ocupadas em relação ao total disponível
                  const DataCell(Text('34 / 40 vagas')),
                  
                  // Célula 5: Nome do docente responsável pela turma
                  const DataCell(Text('Profa. Dra. Helena Bittencourt')),
                  
                  // Célula 6: Botão de ação rápida para supervisão da turma
                  DataCell(ElevatedButton(onPressed: () {}, child: const Text('Supervisionar'))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}