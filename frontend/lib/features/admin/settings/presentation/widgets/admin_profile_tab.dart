// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Aba de configuração do Perfil Administrativo.
///
/// Gerencia identidade visual, nome de exibição (nome civil oficial vs. nome social preferido)
/// e apresenta matrícula oficial e registros institucionais acadêmicos.
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final _profileRemote = AuthProfileRemoteDataSource();
  final _socialNameController = TextEditingController();
  final _civilNameController = TextEditingController();
  Map<String, dynamic> _profile = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRemote.me();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _civilNameController.text =
            profile['displayName']?.toString() ??
            AppUserSession.instance.effectiveName;
        _socialNameController.text =
            profile['socialName']?.toString() ?? '';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _profileRemote.updateProfile({
        'socialName': _socialNameController.text.trim(),
      });
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  String _field(String key, [String fallback = 'Não informado']) =>
      _profile[key]?.toString().trim().isNotEmpty == true
      ? _profile[key].toString()
      : fallback;

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formattedRole() {
    final raw = _field('profile', 'admin').toLowerCase();
    return switch (raw) {
      'admin' => 'Administrador Institucional',
      'docente' => 'Docente',
      'aluno' => 'Discente',
      _ => _field('profile', 'Administrador Institucional'),
    };
  }

  @override
  void dispose() {
    _socialNameController.dispose();
    _civilNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final effectiveName = _field(
      'displayName',
      AppUserSession.instance.effectiveName,
    );
    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
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
        // 1. Cartão de Identidade Visual e Foto
        _buildSectionCard(
          title: 'Identidade Visual & Avatar',
          subtitle:
              'Identificador visual exibido em despachos administrativos e trilhas de auditoria.',
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: InstColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(effectiveName),
                    style: jakarta(
                      color: Colors.white,
                      size: 20,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effectiveName,
                      style: jakarta(
                        size: 15,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedRole(),
                      style: jakarta(size: 12.5, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Cartão de Identificação e Nome de Exibição
        _buildSectionCard(
          title: 'Identificação & Nome de Exibição',
          subtitle:
              'Configure como seu nome deve ser chamado nas comunicações cotidianas da Instituição.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return isNarrow
                  ? Column(
                      children: [
                        _buildCivilNameField(),
                        const SizedBox(height: 16),
                        _buildSocialNameField(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCivilNameField()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSocialNameField()),
                      ],
                    );
            },
          ),
        ),

        const SizedBox(height: 20),

        // 3. Cartão de Registros Institucionais Oficiais
        _buildSectionCard(
          title: 'Vínculo Funcional & Registros',
          subtitle:
              'Dados vinculados ao cadastro institucional e lotação administrativa.',
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: InstColors.stoneActive,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: InstColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 14,
                  color: InstColors.ink,
                ),
                const SizedBox(width: 6),
                Text(
                  'PERFIL ADMINISTRATIVO',
                  style: jakarta(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  return isNarrow
                      ? Column(
                          children: [
                            _buildInfoField(
                              'IDENTIDADE / REGISTRO',
                              _field('identity'),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoField(
                              'LOTAÇÃO / DEPARTAMENTO',
                              _field('departmentOrCourse'),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoField(
                              'PERFIL DE ACESSO',
                              _formattedRole(),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildInfoField(
                                'IDENTIDADE / REGISTRO',
                                _field('identity'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: _buildInfoField(
                                'LOTAÇÃO / DEPARTAMENTO',
                                _field('departmentOrCourse'),
                                icon: Icons.apartment_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: _buildInfoField(
                                'PERFIL DE ACESSO',
                                _formattedRole(),
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              _buildInfoField(
                'POLO / UNIDADE',
                _field('campus'),
                icon: Icons.business_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    Widget? trailingBadge,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      padding: const EdgeInsets.all(24),
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
                      title,
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: jakarta(size: 12.5, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) trailingBadge,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCivilNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nome de Registro Civil',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: InstColors.body,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: InstColors.subtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: InstColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Oficial',
                    style: jakarta(
                      size: 10,
                      weight: FontWeight.w600,
                      color: InstColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _civilNameController,
          enabled: false,
          style: jakarta(size: 13.5, color: InstColors.muted),
          decoration: InstText.inputDecoration().copyWith(
            fillColor: InstColors.stone,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nome civil registrado no cadastro institucional.',
          style: jakarta(size: 11, color: InstColors.faint),
        ),
      ],
    );
  }

  Widget _buildSocialNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nome Social / Preferido',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: InstColors.body,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: InstColors.stoneActive,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Editável',
                style: jakarta(
                  size: 10,
                  weight: FontWeight.w600,
                  color: InstColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _socialNameController,
          style: jakarta(
            size: 13.5,
            weight: FontWeight.w500,
            color: InstColors.ink,
          ),
          decoration: InstText.inputDecoration(
            hintText: 'Como prefere ser identificado nos despachos',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nome exibido nos despachos de secretaria, homologações e cabeçalho.',
          style: jakarta(size: 11, color: InstColors.faint),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: InstColors.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Salvar perfil',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: InstColors.stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: InstColors.muted),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: InstColors.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: InstColors.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
