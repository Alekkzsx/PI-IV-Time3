// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';

/// Tela de Gestão de Usuários & Controle de Acessos da Visão do Administrador.
/// Permite cadastrar novos discentes/docentes com geração automática de R.A. e 2FA,
/// filtrar por perfil, realizar busca textual, redefinir senhas e suspender acessos.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller.filteredUsers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho da Página
                        _buildHeader(context, isDesktop),
                        const SizedBox(height: 28),

                        // Barra de Filtros e Busca em container branco com borda
                        _buildFilterAndSearchBar(isDesktop),
                        const SizedBox(height: 24),

                        // Tabela Institucional de Usuários
                        _buildUsersTable(filteredList),
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Usuários & Controle de Acessos',
          style: jakarta(
            size: isDesktop ? 28 : 24,
            weight: FontWeight.w700,
            color: const Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Emissão de registros acadêmicos (R.A.), matrículas funcionais e governança de credenciais.',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );

    final newCadastroBtn = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _showNovoCadastroModal(context),
      icon: const Icon(Icons.add, size: 16, color: Colors.white),
      label: Text(
        'Novo Cadastro Institucional',
        style: jakarta(
          size: 13.5,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleAndSubtitle),
          const SizedBox(width: 24),
          newCadastroBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleAndSubtitle,
        const SizedBox(height: 18),
        newCadastroBtn,
      ],
    );
  }

  // ==========================================
  // BARRA DE FILTROS E BUSCA
  // ==========================================
  Widget _buildFilterAndSearchBar(bool isDesktop) {
    final filterOptions = ['Todos', 'Discentes', 'Docentes', 'Administração'];

    final searchBox = Container(
      width: isDesktop ? 360 : double.infinity,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _controller.setUserSearchQuery(val),
        style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, R.A. ou e-mail...',
          hintStyle: jakarta(size: 13, color: const Color(0xFFA3A3A3)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFFA3A3A3),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    final filterPills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filterOptions.map((p) {
        final isSelected = _controller.userFilter == p;
        return InkWell(
          onTap: () => _controller.setUserFilter(p),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: Text(
              p,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF525252),
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                searchBox,
                filterPills,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchBox,
                const SizedBox(height: 12),
                filterPills,
              ],
            ),
    );
  }

  // ==========================================
  // TABELA DE USUÁRIOS
  // ==========================================
  Widget _buildUsersTable(List<AdminUserModel> usersList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da Tabela
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF2F0EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        'IDENTIFICAÇÃO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 260,
                      child: Text(
                        'NOME DO USUÁRIO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child: Text(
                        'PERFIL',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 250,
                      child: Text(
                        'CURSO / LOTAÇÃO',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 85,
                      child: Text(
                        'STATUS',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: Text(
                        'AÇÕES DE SEGURANÇA',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Linhas da Tabela
              for (int i = 0; i < usersList.length; i++)
                _buildTableRow(usersList[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(AdminUserModel u) {
    final isAtivo = u.status == 'Ativo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Identificação
          SizedBox(
            width: 130,
            child: Text(
              u.id,
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Nome do Usuário & E-mail
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  u.email,
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Perfil
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildProfileBadge(u.profile),
            ),
          ),
          const SizedBox(width: 16),

          // Curso / Lotação
          SizedBox(
            width: 250,
            child: Text(
              u.departmentOrCourse,
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF525252),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status
          SizedBox(
            width: 85,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isAtivo
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAtivo
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                  ),
                ),
                child: Text(
                  u.status,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: isAtivo
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Ações de Segurança
          SizedBox(
            width: 320,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                InkWell(
                  onTap: () => _showResetSenhaDialog(context, u),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vpn_key_outlined,
                          size: 13,
                          color: Color(0xFF18181B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reset Senha',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _controller.toggleUserStatus(u.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Text(
                      isAtivo ? 'Suspender' : 'Reativar',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge(String profile) {
    Color bg;
    Color border;
    Color textColor;

    if (profile == 'Docente') {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF2563EB);
    } else if (profile == 'Administrador') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFFF4F4F5);
      border = const Color(0xFFE4E4E7);
      textColor = const Color(0xFF52525B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        profile,
        style: jakarta(
          size: 12,
          weight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ==========================================
  // MODAL NOVO CADASTRO INSTITUCIONAL
  // ==========================================
  void _showNovoCadastroModal(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final deptController = TextEditingController(
      text: 'Engenharia de Software (1º Semestre)',
    );
    String selectedRole = 'Discente (Aluno)'; // 'Discente (Aluno)', 'Docente (Professor)', 'Administração'
    String generatedRa = '2024.2.01045';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GESTÃO DE IDENTIDADES & ACESSOS',
                                style: jakarta(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF737373),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Novo Cadastro Institucional',
                                style: jakarta(
                                  size: 22,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF737373),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Tipo de Vínculo Acadêmico
                    Text(
                      'Tipo de Vínculo Acadêmico',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRoleOption(
                          label: 'Discente (Aluno)',
                          isSelected: selectedRole == 'Discente (Aluno)',
                          onTap: () {
                            setModalState(() {
                              selectedRole = 'Discente (Aluno)';
                              generatedRa = '2024.2.01045';
                              deptController.text =
                                  'Engenharia de Software (1º Semestre)';
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildRoleOption(
                          label: 'Docente (Professor)',
                          isSelected: selectedRole == 'Docente (Professor)',
                          onTap: () {
                            setModalState(() {
                              selectedRole = 'Docente (Professor)';
                              generatedRa = 'DOC-88425';
                              deptController.text =
                                  'Departamento de Computação e Sistemas';
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildRoleOption(
                          label: 'Administração',
                          isSelected: selectedRole == 'Administração',
                          onTap: () {
                            setModalState(() {
                              selectedRole = 'Administração';
                              generatedRa = 'ADM-00135';
                              deptController.text =
                                  'Secretaria Geral Acadêmica & Auditoria';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Nome Completo do Usuário
                    Text(
                      'Nome Completo do Usuário',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: jakarta(
                        size: 13.5,
                        color: const Color(0xFF18181B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: Ana Clara Barbosa Ferreira',
                        hintStyle: jakarta(
                          size: 13.5,
                          color: const Color(0xFFA3A3A3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF18181B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // E-mail Institucional
                    Text(
                      'E-mail Institucional',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      style: jakarta(
                        size: 13.5,
                        color: const Color(0xFF18181B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'nome.sobrenome@universidade.edu.br',
                        hintStyle: jakarta(
                          size: 13.5,
                          color: const Color(0xFFA3A3A3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF18181B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Linha dupla: R.A. Gerado Oficial & Curso de Ingresso / Lotação
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'R.A. Gerado Oficial',
                                style: jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE5E5E5),
                                  ),
                                ),
                                child: Text(
                                  generatedRa,
                                  style: jakarta(
                                    size: 13.5,
                                    color: const Color(0xFF18181B),
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curso de Ingresso',
                                style: jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: deptController,
                                style: jakarta(
                                  size: 13.5,
                                  color: const Color(0xFF18181B),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF18181B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Aviso explicativo de 2FA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Será encaminhado um e-mail com senha temporária criptografada e link para ativação de 2FA obrigatório no primeiro acesso.',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botões de Ação
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E5E5)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: jakarta(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();
                            final profile = selectedRole.contains('Discente')
                                ? 'Discente'
                                : selectedRole.contains('Docente')
                                    ? 'Docente'
                                    : 'Administrador';

                            if (name.isNotEmpty && email.isNotEmpty) {
                              _controller.addUser(
                                name: name,
                                email: email,
                                profile: profile,
                                department: deptController.text.trim(),
                                require2FA: true,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Usuário cadastrado com sucesso! Credenciais e token 2FA despachados.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Concluir Cadastro',
                            style: jakarta(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF525252),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DIÁLOGO RESET DE SENHA
  // ==========================================
  void _showResetSenhaDialog(BuildContext context, AdminUserModel u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Redefinição Segura de Credenciais',
          style: jakarta(
            size: 18,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        content: Text(
          'Deseja enviar um link seguro de redefinição de senha com validade de 24 horas para o e-mail:\n\n${u.email}?',
          style: jakarta(
            size: 13.5,
            color: const Color(0xFF525252),
            height: 1.4,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E5E5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancelar',
              style: jakarta(
                size: 13,
                weight: FontWeight.w500,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Link de redefinição enviado com sucesso para ${u.email}!',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirmar Envio',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
