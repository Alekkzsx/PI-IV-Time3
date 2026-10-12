// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart'; // Importa o pacote principal do Material Design para Flutter

// Declaração da tela de Auditoria como um StatelessWidget (componente estático sem estado interno mutável)
class AuditPage extends StatelessWidget {
  const AuditPage({Key? key}) : super(key: key); // Construtor padrão com suporte a chave (key)

  @override
  Widget build(BuildContext context) {
    // Widget que permite a rolagem da página inteira caso o conteúdo exceda a altura disponível
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0), // Adiciona margem interna de 32 pixels em todas as bordas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha todos os elementos filhos à esquerda
        children: [
          // Rótulo superior pequeno contextualizando a seção atual do sistema
          const Text('Auditoria', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8), // Espaçamento vertical entre os textos
          
          // Título principal da página enfatizando a segurança e trilha documental
          const Text('Auditoria de Segurança & Trilha Documental (Audit Trail)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), // Pequeno espaçamento vertical
          
          // Subtítulo descritivo detalhando o propósito do registro de auditoria (logs)
          const Text('Registro irrevogável de lançamentos de notas, deferimentos de protocolos, retificações e tentativas de acesso.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24), // Espaçamento antes do painel de logs
          
          // Container estilizado como cartão para agrupar as informações de auditoria
          Container(
            padding: const EdgeInsets.all(16), // Espaçamento interno dentro do container
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas de 12 pixels
              border: Border.all(color: Colors.grey[200]!) // Borda sutil na cor cinza claro
            ),
            // Item de lista estilizado para exibir um registro individual de log
            child: const ListTile(
              title: Text('Lançamento de nota de avaliação (9.5) para discente Mariana Rios Costa'), // Descrição principal da ação auditada
              subtitle: Text('Agente: Profa. Dra. Helena Bittencourt • IP: 177.136.24.10'), // Detalhes técnicos (quem realizou e o IP de origem)
              trailing: Chip(label: Text('INFO', style: TextStyle(color: Colors.blue))), // Etiqueta indicativa do nível do log (Informativo, em azul)
            ),
          ),
        ],
      ),
    );
  }
}