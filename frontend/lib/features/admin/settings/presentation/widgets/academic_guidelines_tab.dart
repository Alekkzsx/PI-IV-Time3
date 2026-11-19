// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import '../../../shared/controllers/admin_portal_controller.dart';
import 'guidelines_formula_card.dart';
import 'guidelines_metric_card.dart';

/// Aba de diretrizes acadêmicas institucionais (notas de corte, frequência, fórmula e recursos).
class AcademicGuidelinesTab extends StatefulWidget {
  const AcademicGuidelinesTab({super.key});

  @override
  State<AcademicGuidelinesTab> createState() => _AcademicGuidelinesTabState();
}

class _AcademicGuidelinesTabState extends State<AcademicGuidelinesTab> {
  String? _error;
  bool _saving = false;
  String _lastUpdatedLabel = 'Registro institucional vigente';
  List<Map<String, String>> _resources = [];

  final _approvalController = TextEditingController(text: '6');
  final _attendanceController = TextEditingController(text: '75');
  final _specialExamController = TextEditingController(text: '4');
  final _formulaController = TextEditingController(
    text: 'Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)',
  );
  final _resolutionController = TextEditingController(
    text: 'RESOLUÇÃO CONSEPE 2026/04',
  );

  @override
  void initState() {
    super.initState();
    _hydrate(AdminPortalController.instance.institutionalSettings);
    _load();
  }

  void _hydrate(Map<String, dynamic> settings) {
    if (settings.isEmpty) return;
    if (settings['minimumGrade'] != null) {
      _approvalController.text = settings['minimumGrade'].toString();
    }
    if (settings['minimumAttendance'] != null) {
      _attendanceController.text = settings['minimumAttendance'].toString();
    }
    if (settings['specialExamGrade'] != null) {
      _specialExamController.text = settings['specialExamGrade'].toString();
    }
    final formula = settings['evaluationFormula']?.toString();
    if (formula != null && formula.trim().isNotEmpty) {
      _formulaController.text = formula;
    }
    final resolution = settings['resolutionCode']?.toString();
    if (resolution != null && resolution.trim().isNotEmpty) {
      _resolutionController.text = resolution;
    }
    final updatedAtRaw = settings['updatedAt']?.toString();
    final parsed = updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw);
    if (parsed != null) {
      final local = parsed.toLocal();
      final d = local.day.toString().padLeft(2, '0');
      final m = local.month.toString().padLeft(2, '0');
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      _lastUpdatedLabel = '$d/$m/${local.year} às $hh:$mm';
    }
    final rawResources = settings['academicResources'];
    if (rawResources is List) {
      _resources = rawResources
          .whereType<Map>()
          .map(
            (r) => {
              'id': r['id']?.toString() ?? 'res-${_resources.length + 1}',
              'title': r['title']?.toString() ?? '',
              'subtitle':
                  (r['subtitle'] ?? r['description'])?.toString() ?? '',
              'category': r['category']?.toString() ?? 'APOIO ACADÊMICO',
              'actionLabel': r['actionLabel']?.toString() ?? 'Acessar',
              'url': r['url']?.toString() ?? '',
              'icon': r['icon']?.toString() ?? 'menu_book',
            },
          )
          .where((r) => r['title']!.isNotEmpty)
          .toList();
    }
  }

  Future<void> _load() async {
    final portal = AdminPortalController.instance;
    if (!portal.usesRemote || AppUserSession.instance.accessToken == null) {
      return;
    }
    try {
      final settings = await portal.remote.request('GET', '/settings') as Map;
      if (!mounted) return;
      final normalized = Map<String, dynamic>.from(settings);
      portal.institutionalSettings = normalized;
      setState(() => _hydrate(normalized));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar as diretrizes.');
      }
    }
  }

  double? _parseDecimal(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final grade = _parseDecimal(_approvalController.text);
    final attendance = _parseDecimal(_attendanceController.text);
    final exam = _parseDecimal(_specialExamController.text);
    if (grade == null || attendance == null || exam == null) {
      setState(() => _error = 'Informe valores numéricos válidos.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final portal = AdminPortalController.instance;
    final payload = <String, Object?>{
      'minimumGrade': grade,
      'minimumAttendance': attendance,
      'specialExamGrade': exam,
      'evaluationFormula': _formulaController.text.trim(),
      'resolutionCode': _resolutionController.text.trim(),
      'academicResources': _resources
          .map(
            (r) => {
              'id': r['id'] ?? 'res-custom',
              'title': r['title'] ?? '',
              'description': r['subtitle'] ?? '',
              'subtitle': r['subtitle'] ?? '',
              'category': r['category'] ?? 'APOIO ACADÊMICO',
              'actionLabel': r['actionLabel'] ?? 'Acessar',
              'url': r['url'] ?? 'https://agmrm.edu.br',
              'icon': r['icon'] ?? 'menu_book',
            },
          )
          .toList(),
    };
    final ok = await portal.updateSettings(payload);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = ok ? null : portal.remoteError;
      if (ok) {
        final now = DateTime.now();
        final d = now.day.toString().padLeft(2, '0');
        final m = now.month.toString().padLeft(2, '0');
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        _lastUpdatedLabel = '$d/$m/${now.year} às $hh:$mm';
        portal.institutionalSettings = {
          ...portal.institutionalSettings,
          ...payload,
        };
      }
    });
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diretrizes salvas.')));
    }
  }

  Future<void> _addResourceModal() async {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final categoryCtrl = TextEditingController(text: 'ACERVO & PESQUISA');
    final actionCtrl = TextEditingController(text: 'Acessar');

    final added = await AcademicModalDialog.show<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AcademicModalDialog(
        title: 'Adicionar Recurso Acadêmico',
        subtitle: 'Publicado no bloco de apoio acadêmico do Portal Discente.',
        icon: Icons.menu_book_outlined,
        maxWidth: 500,
        confirmLabel: 'Adicionar',
        onConfirm: () {
          if (titleCtrl.text.trim().length < 2 ||
              urlCtrl.text.trim().isEmpty) {
            return;
          }
          Navigator.pop(dialogContext, {
            'id': 'res-${DateTime.now().millisecondsSinceEpoch}',
            'title': titleCtrl.text.trim(),
            'subtitle': subtitleCtrl.text.trim(),
            'category': categoryCtrl.text.trim().isEmpty
                ? 'APOIO ACADÊMICO'
                : categoryCtrl.text.trim(),
            'actionLabel': actionCtrl.text.trim().isEmpty
                ? 'Acessar'
                : actionCtrl.text.trim(),
            'url': urlCtrl.text.trim(),
            'icon': 'menu_book',
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: jakarta(size: 13.5, color: InstColors.ink),
              decoration: InstText.inputDecoration(
                labelText: 'Título do recurso',
                hintText: 'Ex: Biblioteca Digital Pearson',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleCtrl,
              style: jakarta(size: 13.5, color: InstColors.ink),
              decoration: InstText.inputDecoration(
                labelText: 'Descrição resumida',
                hintText: 'Ex: Acesso gratuito a periódicos e livros técnicos',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: jakarta(size: 13.5, color: InstColors.ink),
              decoration: InstText.inputDecoration(labelText: 'URL de acesso'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: categoryCtrl,
                    style: jakarta(size: 13.5, color: InstColors.ink),
                    decoration: InstText.inputDecoration(labelText: 'Categoria'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: actionCtrl,
                    style: jakarta(size: 13.5, color: InstColors.ink),
                    decoration: InstText.inputDecoration(
                      labelText: 'Rótulo do botão',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    urlCtrl.dispose();
    categoryCtrl.dispose();
    actionCtrl.dispose();
    if (added != null && mounted) {
      setState(() => _resources = [..._resources, added]);
    }
  }

  @override
  void dispose() {
    _approvalController.dispose();
    _attendanceController.dispose();
    _specialExamController.dispose();
    _formulaController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBanner(),
          const SizedBox(height: 24),
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          GuidelinesFormulaCard(
            formulaController: _formulaController,
            resolutionController: _resolutionController,
            lastUpdatedLabel: _lastUpdatedLabel,
          ),
          const SizedBox(height: 24),
          _buildResourcesSection(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InstColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: InstColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _error!,
                style: jakarta(size: 13, color: InstColors.danger),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: InstColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _saving ? 'Salvando...' : 'Salvar diretrizes',
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: InstColors.stoneActive,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: InstColors.border),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: InstColors.ink,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diretrizes Acadêmicas Regimentais',
                style: jakarta(
                  size: 18,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Definição institucional centralizada das metas de frequência, notas de corte e regras de aprovação.',
                style: jakarta(size: 13, color: InstColors.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: InstColors.successBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: InstColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: InstColors.success,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Governança Central Ativa',
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w600,
                  color: InstColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InstColors.stone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: InstColors.ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hierarquia Institucional e Autonomia Docente:\n'
              'Os professores mantêm autonomia pedagógica para avaliações e diários nas turmas sem bloqueio, '
              'enquanto as notas de corte para aprovação direta, exame especial e frequência mínima refletem as diretrizes aqui definidas em todos os portais.',
              style: jakarta(size: 13, color: InstColors.body, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;
        final approvalCard = GuidelinesMetricCard(
          icon: Icons.calculate_outlined,
          iconColor: InstColors.ink,
          title: 'MÉDIA DE APROVAÇÃO',
          badgeText: 'Aprovação Direta',
          badgeBg: InstColors.stoneActive,
          badgeBorder: InstColors.border,
          badgeTextColor: InstColors.ink,
          subtitle:
              'Nota de Corte Mínima (0 a 10)\nMédia semestral exigida para aprovação sem necessidade de exame.',
          controller: _approvalController,
          footerText: 'Aplicada automaticamente no Boletim e Livro de Notas.',
        );

        final attendanceCard = GuidelinesMetricCard(
          icon: Icons.percent_rounded,
          iconColor: InstColors.success,
          title: 'FREQUÊNCIA PRESENCIAL',
          badgeText: 'LDB 9.394/96',
          badgeBg: InstColors.successBg,
          badgeBorder: InstColors.success.withValues(alpha: 0.3),
          badgeTextColor: InstColors.success,
          subtitle:
              'Presença Mínima Obrigatória (%)\nAbaixo deste índice o aluno é reprovado por infrequência (RF).',
          controller: _attendanceController,
          suffixText: '%',
          footerText: 'Padrão regimental institucional: 75%',
        );

        final examCard = GuidelinesMetricCard(
          icon: Icons.description_outlined,
          iconColor: InstColors.warning,
          title: 'EXAME ESPECIAL',
          badgeText: 'Recuperação',
          badgeBg: InstColors.warningBg,
          badgeBorder: InstColors.warning.withValues(alpha: 0.35),
          badgeTextColor: InstColors.warning,
          subtitle:
              'Corte para Prova Final (0 a 10)\nNota mínima para discentes em faixa de exame especial.',
          controller: _specialExamController,
          footerText: 'Abaixo deste corte: Reprovação direta por nota.',
        );

        if (isNarrow) {
          return Column(
            children: [
              approvalCard,
              const SizedBox(height: 16),
              attendanceCard,
              const SizedBox(height: 16),
              examCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: approvalCard),
            const SizedBox(width: 16),
            Expanded(child: attendanceCard),
            const SizedBox(width: 16),
            Expanded(child: examCard),
          ],
        );
      },
    );
  }

  Widget _buildResourcesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recursos & Bibliotecas Acadêmicas',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Links institucionais exibidos nos cartões de apoio do Portal Discente.',
                      style: jakarta(size: 12, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addResourceModal,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Novo recurso',
                  style: jakarta(size: 12.5, weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          if (_resources.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Nenhum recurso adicional cadastrado no momento.',
              style: jakarta(size: 12, color: InstColors.muted),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (var i = 0; i < _resources.length; i++)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: InstColors.stone,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: InstColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resources[i]['title'] ?? '',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w600,
                              color: InstColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_resources[i]['subtitle']} · ${_resources[i]['url']}',
                            style: jakarta(size: 11.5, color: InstColors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover recurso',
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: InstColors.danger,
                      ),
                      onPressed: () => setState(() => _resources.removeAt(i)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
