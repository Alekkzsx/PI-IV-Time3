// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card para gerenciamento de preferências do sistema, tema, acessibilidade e formato de data discente.
class StudentSystemPreferencesCard extends StatefulWidget {
  const StudentSystemPreferencesCard({super.key});

  @override
  State<StudentSystemPreferencesCard> createState() =>
      _StudentSystemPreferencesCardState();
}

class _StudentSystemPreferencesCardState
    extends State<StudentSystemPreferencesCard> {
  // Aparência & Tema
  String _selectedTheme = 'claro'; // 'claro', 'escuro', 'sistema'

  // Acessibilidade & Leitura
  String _typographyScale = 'Normal (100%)';
  String _tableDensity = 'Confortável';
  bool _highContrast = false;
  bool _reduceMotion = false;

  // Preferências do Calendário Acadêmico
  String _firstDayOfWeek = 'Domingo (Padrão)';
  bool _hideWeekends = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Aparência & Tema
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aparência & Tema da Interface',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Defina a identidade visual da plataforma para seus momentos de estudo.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'claro',
                      title: 'Claro (Padrão AGMRM)',
                      description:
                          'Visual padrão com fundo claro e tipografia de alto contraste.',
                      icon: Icons.light_mode_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'escuro',
                      title: 'Modo Noturno',
                      description:
                          'Reduz fadiga ocular em estudos noturnos ou baixa luminosidade.',
                      icon: Icons.dark_mode_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildThemeOptionCard(
                      id: 'sistema',
                      title: 'Sincronizar com SO',
                      description:
                          'Alterna automaticamente com o tema configurado no dispositivo.',
                      icon: Icons.brightness_auto_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Acessibilidade & Densidade de Visualização
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acessibilidade, Fontes & Densidade',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajustes de escala tipográfica e espaçamento de tabelas de notas e tarefas.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

              // Escala Tipográfica
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escala Tipográfica da Interface',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aumente o tamanho de textos caso utilize monitores de alta densidade.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: DropdownButton<String>(
                      value: _typographyScale,
                      underline: const SizedBox(),
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Normal (100%)',
                          child: Text('Normal (100%)'),
                        ),
                        DropdownMenuItem(
                          value: 'Média (+10%)',
                          child: Text('Média (+10%)'),
                        ),
                        DropdownMenuItem(
                          value: 'Grande (+20%)',
                          child: Text('Grande (+20%)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _typographyScale = val);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Densidade de Tabelas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Densidade de Tabelas e Listas',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Controle a altura das linhas em diários de presença e boletins de notas.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: DropdownButton<String>(
                      value: _tableDensity,
                      underline: const SizedBox(),
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Confortável',
                          child: Text('Confortável'),
                        ),
                        DropdownMenuItem(
                          value: 'Compacto',
                          child: Text('Compacto'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _tableDensity = val);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Alto Contraste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo de Alto Contraste (WCAG AAA)',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maximiza a separação entre texto e elementos de fundo para acessibilidade.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _highContrast,
                    onChanged: (v) => setState(() => _highContrast = v),
                    activeTrackColor: const Color(0xFF16A34A),
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Reduzir Movimento
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reduzir Movimento e Transições',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Desativa micro-animações em modais e transições de tela no portal.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _reduceMotion,
                    onChanged: (v) => setState(() => _reduceMotion = v),
                    activeTrackColor: const Color(0xFF16A34A),
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Formato, Horário & Calendário Acadêmico
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Localização & Calendário Acadêmico',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Padrões de fuso horário, formato de datas e dias de aula.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

              // Formato de Data & Fuso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formato de Data e Horário',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DD/MM/AAAA • 24 Horas (Horário Oficial de Brasília - UTC-3)',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Text(
                      'DD/MM/AAAA (24h)',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Primeiro dia da semana
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primeiro Dia da Semana no Calendário',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Define qual dia aparece na primeira coluna da grade mensal de estudos.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: DropdownButton<String>(
                      value: _firstDayOfWeek,
                      underline: const SizedBox(),
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Domingo (Padrão)',
                          child: Text('Domingo (Padrão)'),
                        ),
                        DropdownMenuItem(
                          value: 'Segunda-feira',
                          child: Text('Segunda-feira'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _firstDayOfWeek = val);
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Ocultar Finais de Semana
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ocultar Finais de Semana no Cronograma Semanal',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exibe apenas de Segunda a Sexta nas visualizações de horário de aula.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _hideWeekends,
                    onChanged: (v) => setState(() => _hideWeekends = v),
                    activeTrackColor: const Color(0xFF16A34A),
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botão de Salvar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preferências de sistema e acessibilidade salvas com sucesso!',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Salvar Preferências do Sistema',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOptionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedTheme == id;

    return InkWell(
      onTap: () => setState(() => _selectedTheme = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF18181B)
                      : const Color(0xFF71717A),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF18181B)
                          : const Color(0xFFA1A1AA),
                      width: isSelected ? 5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: jakarta(size: 10.5, color: const Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }
}
