import 'package:flutter/material.dart';
import '../../../admin_panel/presentation/pages/panel_geral_page.dart';
import '../../../users/presentations/pages/users_page.dart';
import '../../../course/presentation/pages/courses_page.dart';
import '../../../classes/presentation/pages/classes_page.dart';
import '../../../secretary/presentation/pages/secretary_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../audit/presentation/pages/audit_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({Key? key}) : super(key: key);

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const PainelGeralPage(),
    const UsersPage(),
    const CoursesPage(),
    const ClassesPage(),
    const SecretaryPage(),
    const CalendarPage(),
    const AuditPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar / Menu Lateral
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Header
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
                const Divider(height: 1),
                // Itens do Menu
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
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo Dinâmico da Tela Selecionada
          Expanded(
            child: Column(
              children: [
                // Barra Superior
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.schedule), onPressed: () {}),
                      const SizedBox(width: 12),
                      IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.black : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[800],
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}