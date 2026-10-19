// Desenvolvido por Guilherme Henrique Moreira e Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
// Importações das diferentes páginas/módulos gerenciados pelo menu lateral (shell)
import '../../../admin_panel/presentation/pages/panel_geral_page.dart';
import '../../../users/presentations/pages/users_page.dart';
import '../../../course/presentation/pages/courses_page.dart';
import '../../../classes/presentation/pages/classes_page.dart';
import '../../../secretary/presentation/pages/secretary_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../audit/presentation/pages/audit_page.dart';
import '../../../configure/presentation/pages/admin_configure_page.dart';

// Declaração do painel principal (Shell/Layout base) como um StatefulWidget, pois ele controla o estado da página atualmente selecionada
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0; // Índice da página ativa no momento (inicializa na página 0: Painel Geral)

  // Lista contendo todas as instâncias das telas do painel administrativo
  final List<Widget> _pages = [
    const PainelGeralPage(), // Índice 0
    const UsersPage(),       // Índice 1
    const CoursesPage(),     // Índice 2
    const ClassesPage(),     // Índice 3
    const SecretaryPage(),   // Índice 4
    const CalendarPage(),    // Índice 5
    const AuditPage(),       // Índice 6
    const AdminConfigurePage(), // Índice 7
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Estrutura principal dividida horizontalmente em duas partes: Menu Lateral e Conteúdo
      body: Row(
        children: [
          // -----------------------------------------------------------------
          // 1. SIDEBAR / MENU LATERAL DE NAVEGAÇÃO
          // -----------------------------------------------------------------
          Container(
            width: 260, // Largura fixa padrão para barras laterais de painéis web/desktop
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho da Marca / Logotipo na Sidebar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AGMRM',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PORTAL GESTÃO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1), // Linha divisória sutil abaixo do logotipo
                
                // Lista de Itens do Menu Lateral (Expandida para ocupar o espaço vertical disponível)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _buildMenuItem(0, Icons.grid_view_rounded, 'Painel Geral'),
                      _buildMenuItem(1, Icons.people_outline_rounded, 'Usuários'),
                      _buildMenuItem(2, Icons.school_outlined, 'Cursos'),
                      _buildMenuItem(3, Icons.menu_book_rounded, 'Turmas'),
                      _buildMenuItem(4, Icons.description_outlined, 'Secretaria'),
                      _buildMenuItem(5, Icons.calendar_today_outlined, 'Calendário'),
                      _buildMenuItem(6, Icons.verified_user_outlined, 'Auditoria'),
                      _buildMenuItem(7, Icons.settings_outlined, 'Configurações'),
                    ],
                  ),
                ),
                const Divider(height: 1), // Divisório acima do botão de saída
                
                // Botão de Logout / Sair localizado na base da barra lateral
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () {}, // Ação de encerramento de sessão (atualmente vazia)
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
          
          // -----------------------------------------------------------------
          // 2. CONTEÚDO DINÂMICO DA TELA SELECIONADA (ÁREA PRINCIPAL)
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                // Barra Superior (App Bar customizada)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(_selectedIndex),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.schedule), onPressed: () {}),
                      const SizedBox(width: 12),
                      IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                    ],
                  ),
                ),
                
                // Área onde a página correspondente ao índice selecionado é renderizada
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC), // Fundo levemente acinzentado/azulado para contraste moderno
                    child: _pages[_selectedIndex], // Exibe a tela ativa com base no índice atual
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para construir cada item do menu com destaque visual condicional
  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index; // Verifica se este item está selecionado
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Adiciona um fundo sutil escuro se o item estiver selecionado, senão fica transparente
        color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        // Altera a cor do ícone dependendo se o item está selecionado ou não
        leading: Icon(icon, color: isSelected ? Colors.black : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[800],
          ),
        ),
        // Ao tocar no item, atualiza o estado alterando o índice ativo e redesenhando a tela
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Painel Geral';
      case 1:
        return 'Usuários';
      case 2:
        return 'Cursos';
      case 3:
        return 'Turmas';
      case 4:
        return 'Secretaria';
      case 5:
        return 'Calendário';
      case 6:
        return 'Auditoria';
      case 7:
        return 'Configurações';
      default:
        return '';
    }
  }
}