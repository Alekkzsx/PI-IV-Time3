import 'package:flutter/material.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> usuarios = [
      {'id': '2024.1.00892', 'nome': 'Gabriel Soares de Oliveira', 'email': 'gabriel.oliveira@aluno.universidade.edu.br', 'perfil': 'Discente', 'curso': 'Engenharia de Software (5º Semestre)', 'status': 'Ativo'},
      {'id': 'DOC-88410', 'nome': 'Profa. Dra. Helena Bittencourt', 'email': 'helena.bittencourt@docente.universidade.edu.br', 'perfil': 'Docente', 'curso': 'Departamento de Computação e Sistemas', 'status': 'Ativo'},
      {'id': 'ADM-00129', 'nome': 'Carlos Eduardo Mendes', 'email': 'carlos.mendes@secretaria.universidade.edu.br', 'perfil': 'Administrador', 'curso': 'Secretaria Geral Acadêmica & Auditoria', 'status': 'Ativo'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuários', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestão de Usuários & Controle de Acessos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Emissão de registros acadêmicos (R.A.), matrículas funcionais e governança de credenciais.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Cadastro Institucional'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = usuarios[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: Text(u['nome']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['id']} • ${u['email']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text(u['perfil']!)),
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: () {}, child: const Text('Reset Senha')),
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