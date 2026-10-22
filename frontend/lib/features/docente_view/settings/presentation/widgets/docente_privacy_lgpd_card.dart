// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card para gerenciamento de privacidade, visibilidade de dados funcionais e direitos LGPD.
class DocentePrivacyLgpdCard extends StatefulWidget {
  const DocentePrivacyLgpdCard({super.key});

  @override
  State<DocentePrivacyLgpdCard> createState() => _DocentePrivacyLgpdCardState();
}

class _DocentePrivacyLgpdCardState extends State<DocentePrivacyLgpdCard> {
  bool _exibirEmailTurma = true;
  bool _mostrarStatusPresenca = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Visibilidade de Perfil & Dados entre Colegas
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
                'Visibilidade de Perfil & Dados entre Colegas',
                style: jakarta(size: 14, weight: FontWeight.w700, color: const Color(0xFF18181B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Controle quais informações ficam visíveis para outros docentes e alunos da instituição.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

              // Exibir e-mail nas turmas
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _exibirEmailTurma,
                      onChanged: (v) => setState(() => _exibirEmailTurma = v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exibir meu e-mail institucional nas listagens de turma', style: jakarta(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Permite que alunos matriculados vejam seu e-mail funcional na lista de participantes da disciplina.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Mostrar status de presença
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _mostrarStatusPresenca,
                      onChanged: (v) => setState(() => _mostrarStatusPresenca = v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mostrar status de presença ("Online recentemente")', style: jakarta(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF18181B))),
                        const SizedBox(height: 2),
                        Text('Exibe indicador de presença ativa para colegas de departamento e alunos quando estiver logado.', style: jakarta(size: 11, color: const Color(0xFF71717A))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Privacidade & Direitos do Titular (LGPD)
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
                'Privacidade & Direitos do Titular (LGPD)',
                style: jakarta(size: 14, weight: FontWeight.w700, color: const Color(0xFF18181B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), você pode gerenciar e auditar todos os seus dados pessoais armazenados na plataforma.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),

              // Aviso Legal LGPD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF18181B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Seus dados são utilizados exclusivamente para fins acadêmicos, registro funcional e cumprimento das obrigações com o Ministério da Educação (MEC). Nós não compartilhamos informações com terceiros para fins comerciais.',
                        style: jakarta(size: 11.5, color: const Color(0xFF52525B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Exportar Relatório de Dados Cadastrais & Histórico
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exportar Relatório de Dados Cadastrais & Histórico',
                            style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Faça o download de uma cópia completa dos seus dados funcionais, históricos de turmas e logs de atividades acadêmicas registradas em sua conta.',
                            style: jakarta(size: 11, color: const Color(0xFF71717A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download do arquivo JSON iniciado...'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.data_object_rounded, size: 15, color: Color(0xFF18181B)),
                          label: Text(
                            'Arquivo JSON',
                            style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE4E4E7)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download do relatório (.txt) iniciado...'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description_outlined, size: 15, color: Colors.white),
                          label: Text(
                            'Relatório (.txt)',
                            style: jakarta(size: 12, weight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Botão Salvar Preferências
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferências de privacidade salvas com sucesso!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            label: Text(
              'Salvar Preferências de Privacidade',
              style: jakarta(size: 13, weight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

