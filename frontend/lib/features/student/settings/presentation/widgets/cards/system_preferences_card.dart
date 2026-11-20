// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../common/settings_common_widgets.dart';

/// [SystemPreferencesCard]
///
/// Componente de customização de preferências de usabilidade, aparência e acessibilidade do sistema.
/// Configura o tema visual (Claro, Escuro, Sistema), escala tipográfica, densidade das tabelas,
/// modo de alto contraste, redução de movimentos e personalizações do calendário acadêmico.
class SystemPreferencesCard extends StatefulWidget {
  /// Cria uma nova instância de [SystemPreferencesCard].
  const SystemPreferencesCard({super.key});

  @override
  State<SystemPreferencesCard> createState() =>
      _StudentSystemPreferencesCardState();
}

class _StudentSystemPreferencesCardState
    extends State<SystemPreferencesCard> {
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
  final AuthProfileRemoteDataSource _remote = AuthProfileRemoteDataSource();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final saved = AppUserSession.instance.preferences['system'];
    if (saved is Map) {
      _selectedTheme = saved['theme']?.toString() ?? _selectedTheme;
      _typographyScale =
          saved['typographyScale']?.toString() ?? _typographyScale;
      _tableDensity = saved['tableDensity']?.toString() ?? _tableDensity;
      _highContrast = saved['highContrast'] == true;
      _reduceMotion = saved['reduceMotion'] == true;
      _firstDayOfWeek =
          saved['firstDayOfWeek']?.toString() ?? _firstDayOfWeek;
      _hideWeekends = saved['hideWeekends'] == true;
    } else {
      _highContrast = false;
      _reduceMotion = false;
      _hideWeekends = false;
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final preferences = Map<String, dynamic>.from(
      AppUserSession.instance.preferences,
    )..['system'] = {
        'theme': _selectedTheme,
        'typographyScale': _typographyScale,
        'tableDensity': _tableDensity,
        'highContrast': _highContrast,
        'reduceMotion': _reduceMotion,
        'firstDayOfWeek': _firstDayOfWeek,
        'hideWeekends': _hideWeekends,
      };
    try {
      await _remote.updateProfile({'preferences': preferences});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências do sistema salvas.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Aparência & Tema
        SettingsSectionCard(
          icon: Icons.palette_outlined,
          title: 'Aparência & Tema da Interface',
          subtitle:
              'Defina a identidade visual da plataforma para seus momentos de estudo.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final claroCard = _buildThemeOptionCard(
                id: 'claro',
                title: 'Claro (Padrão AGMRM)',
                description:
                    'Visual padrão com fundo claro e tipografia de alto contraste.',
                icon: Icons.light_mode_outlined,
              );
              final escuroCard = _buildThemeOptionCard(
                id: 'escuro',
                title: 'Modo Noturno',
                description:
                    'Reduz fadiga ocular em estudos noturnos ou baixa luminosidade.',
                icon: Icons.dark_mode_outlined,
              );
              final sistemaCard = _buildThemeOptionCard(
                id: 'sistema',
                title: 'Sincronizar com SO',
                description:
                    'Alterna automaticamente com o tema configurado no dispositivo.',
                icon: Icons.brightness_auto_outlined,
              );

              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    claroCard,
                    const SizedBox(height: 12),
                    escuroCard,
                    const SizedBox(height: 12),
                    sistemaCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: claroCard),
                  const SizedBox(width: 14),
                  Expanded(child: escuroCard),
                  const SizedBox(width: 14),
                  Expanded(child: sistemaCard),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // 2. Acessibilidade & Densidade de Visualização
        SettingsSectionCard(
          icon: Icons.accessibility_new_rounded,
          title: 'Acessibilidade, Fontes & Densidade',
          subtitle:
              'Ajustes de escala tipográfica e espaçamento de tabelas de notas e tarefas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Escala Tipográfica
              _buildPreferenceRow(
                title: 'Escala Tipográfica da Interface',
                subtitle:
                    'Aumente o tamanho de textos caso utilize monitores de alta densidade.',
                control: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
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
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Densidade de Tabelas
              _buildPreferenceRow(
                title: 'Densidade de Tabelas e Listas',
                subtitle:
                    'Controle a altura das linhas em diários de presença e boletins de notas.',
                control: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
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
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Alto Contraste
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 12),
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
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 12),
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
        SettingsSectionCard(
          icon: Icons.calendar_month_outlined,
          title: 'Localização & Calendário Acadêmico',
          subtitle:
              'Padrões de fuso horário, formato de datas e dias de aula.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formato de Data & Fuso
              _buildPreferenceRow(
                title: 'Formato de Data e Horário',
                subtitle:
                    'DD/MM/AAAA • 24 Horas (Horário Oficial de Brasília - UTC-3)',
                control: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
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
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Primeiro dia da semana
              _buildPreferenceRow(
                title: 'Primeiro Dia da Semana no Calendário',
                subtitle:
                    'Define qual dia aparece na primeira coluna da grade mensal de estudos.',
                control: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
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
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Ocultar Finais de Semana
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 12),
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
              SettingsSaveButton(
                label: 'Salvar Preferências do Sistema',
                onPressed: _isSaving ? null : _savePreferences,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow({
    required String title,
    required String subtitle,
    required Widget control,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: jakarta(
                size: 11,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textBlock,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: control),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: textBlock),
            const SizedBox(width: 12),
            control,
          ],
        );
      },
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


typedef StudentSystemPreferencesCard = SystemPreferencesCard;
