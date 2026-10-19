// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de configuração de Governança e Privacidade (LGPD).
///
/// Permite gerenciar a visibilidade de dados corporativos e estudantis entre pares,
/// assegurar direitos do titular conforme a Lei nº 13.709/2018 e exportar relatórios cadastrais.
class GovernanceLgpdTab extends StatefulWidget {
  const GovernanceLgpdTab({super.key});

  @override
  State<GovernanceLgpdTab> createState() => _GovernanceLgpdTabState();
}

class _GovernanceLgpdTabState extends State<GovernanceLgpdTab> {
  bool _showEmailInLists = false;
  bool _showOnlineStatus = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Visibilidade de Perfil & Dados entre Colegas
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    'Visibilidade de Perfil & Dados entre Colegas',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Controle quais informações ficam visíveis para outros alunos matriculados nas mesmas turmas.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Item 1: Exibir meu e-mail nas listagens de turma
              _buildVisibilityRow(
                title: 'Exibir meu e-mail nas listagens de turma',
                subtitle: 'Permite que colegas vejam seu e-mail institucional para formar grupos de estudo.',
                value: _showEmailInLists,
                onChanged: (val) => setState(() => _showEmailInLists = val ?? false),
              ),

              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Item 2: Mostrar status de presença ("Online recentemente")
              _buildVisibilityRow(
                title: 'Mostrar status de presença ("Online recentemente")',
                subtitle: 'Indica no chat de disciplinas e fóruns se você esteve ativo nas últimas 24 horas.',
                value: _showOnlineStatus,
                onChanged: (val) => setState(() => _showOnlineStatus = val ?? false),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Privacidade & Direitos do Titular (LGPD)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.privacy_tip_outlined, size: 20, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    'Privacidade & Direitos do Titular (LGPD)',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), você pode obter uma cópia integral dos seus registros acadêmicos e interações na plataforma.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 20),

              // Box de Exportação de Relatório
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    return isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExportInfo(),
                              const SizedBox(height: 14),
                              _buildExportButtons(context),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildExportInfo()),
                              const SizedBox(width: 16),
                              _buildExportButtons(context),
                            ],
                          );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Botão Final: Salvar Preferências de Privacidade
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferências de privacidade atualizadas com sucesso.'),
                    backgroundColor: Color(0xFF059669),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Salvar Preferências de Privacidade',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisibilityRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Checkbox(
          value: value,
          activeColor: const Color(0xFF0F172A),
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildExportInfo() {
    return Row(
      children: [
        const Icon(Icons.description_outlined, size: 20, color: Color(0xFF475569)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Exportar Relatório de Dados Cadastrais & Histórico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Inclui notas, presenças, registros de logins e mensagens submetidas.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download do arquivo JSON iniciado.')),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 15),
          label: const Text('Arquivo JSON', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download do relatório .txt iniciado.')),
            );
          },
          icon: const Icon(Icons.download_rounded, size: 15),
          label: const Text('Relatório (.txt)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }
}
