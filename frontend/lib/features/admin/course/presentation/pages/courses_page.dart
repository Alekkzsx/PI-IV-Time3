// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';

// Tela responsável por exibir os cursos disponíveis.
class CoursesPage extends StatelessWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Permite rolar a página caso o conteúdo não caiba.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cursos', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Cursos & Matrizes Curriculares (PPC)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Estrutura pedagógica institucional, carga horária regimental e parametrização das fórmulas de avaliação.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          // Cartão do curso de Engenharia de Software.
          _buildCourseCard('ENG-SOFT-2024', 'Bacharelado em Engenharia de Software', 'Matriz 2024/1 (PPC Atualizado)', '3200h / 210 créditos', '420 alunos', 'Média = (N1 x 0.4) + (N2 x 0.6) • Freq. ≥ 75%'),

          const SizedBox(height: 16),

          // Cartão do curso de Sistemas de Informação.
          _buildCourseCard('SIS-INFO-2023', 'Bacharelado em Sistemas de Informação', 'Matriz 2023/1', '3000h / 195 créditos', '380 alunos', 'Média = (N1 x 0.4) + (N2 x 0.6) • Freq. ≥ 75%'),
        ],
      ),
    );
  }

  // Cria um cartão reutilizável com os dados de cada curso.
  Widget _buildCourseCard(String code, String title, String matriz, String carga, String discentes, String formula) {
    return Container(
      padding: const EdgeInsets.all(24),

      // Define o fundo branco, as bordas arredondadas e a borda cinza.
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Exibe o código do curso em uma etiqueta.
              Chip(label: Text(code)),
              const Text('Graduação', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // Mostra o nome do curso.
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            // Exibe a matriz, a carga horária e os alunos matriculados.
            children: [
              Text('Matriz Homologada: $matriz'),
              Text('Carga Horária: $carga'),
              Text('Discentes Matriculados: $discentes'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Apresenta a fórmula e os critérios para aprovação.
          Text('CRITÉRIO REGIMENTAL DE APROVAÇÃO: $formula', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }
}