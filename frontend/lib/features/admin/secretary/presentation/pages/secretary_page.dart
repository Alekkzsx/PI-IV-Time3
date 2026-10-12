// Desenvolvido por Guilherme Henrique Moreira
// Importa a biblioteca de componentes visuais do Flutter.
import 'package:flutter/material.dart';

// Cria a classe SecretaryPage, responsável pela tela da Secretaria.
// StatelessWidget indica que a tela não possui estado mutável próprio.
class SecretaryPage extends StatelessWidget {

  // Construtor da classe.
  // O parâmetro Key é opcional e ajuda o Flutter a identificar o widget.
  const SecretaryPage({Key? key}) : super(key: key);

  // Método responsável por construir e retornar a interface da tela.
  @override
  Widget build(BuildContext context) {

    // Permite rolar a tela verticalmente caso o conteúdo não caiba.
    return SingleChildScrollView(

      // Define um espaçamento de 32 pixels entre o conteúdo e as bordas.
      padding: const EdgeInsets.all(32.0),

      // Organiza os elementos filhos em uma coluna vertical.
      child: Column(

        // Alinha os elementos à esquerda.
        crossAxisAlignment: CrossAxisAlignment.start,

        // Lista de elementos que serão exibidos na tela.
        children: [

          // Exibe a categoria "Secretaria" em tamanho pequeno e cinza.
          const Text(
            'Secretaria',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          // Adiciona um espaço vertical de 8 pixels.
          const SizedBox(height: 8),

          // Exibe o título principal da página em negrito.
          const Text(
            'Secretaria Acadêmica Geral & Protocolos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Adiciona um espaço vertical de 4 pixels.
          const SizedBox(height: 4),

          // Exibe uma descrição das atividades realizadas pela secretaria.
          // O texto utiliza a cor cinza para ter menos destaque.
          const Text(
            'Mesa de análise de atestados médicos, pedidos de segunda '
            'chamada, trancamentos e validação de horas complementares.',
            style: TextStyle(color: Colors.grey),
          ),

          // Adiciona um espaço vertical de 24 pixels antes do protocolo.
          const SizedBox(height: 24),

          // Cria um contêiner que funciona como um cartão visual.
          Container(

            // Define um espaçamento interno de 16 pixels.
            padding: const EdgeInsets.all(16),

            // Configura a aparência do cartão.
            decoration: BoxDecoration(

              // Define o fundo do cartão como branco.
              color: Colors.white,

              // Arredonda os cantos do cartão em 12 pixels.
              borderRadius: BorderRadius.circular(12),

              // Adiciona uma borda cinza-clara ao redor do cartão.
              border: Border.all(color: Colors.grey[200]!),
            ),

            // Organiza as informações do protocolo em uma única linha.
            child: const ListTile(

              // Exibe o número de identificação do protocolo.
              title: Text('PROT-2026/8841'),

              // Exibe o nome da pessoa, a matrícula e o tipo de solicitação.
              subtitle: Text(
                'Camila Duarte Fagundes (2024.1.00962) • '
                'ATESTADO MÉDICO',
              ),

              // Exibe um indicador de status no lado direito do cartão.
              trailing: Chip(
                // Define o texto do indicador como "Deferido".
                label: Text(
                  'Deferido',

                  // Define a cor do texto do status como verde.
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}