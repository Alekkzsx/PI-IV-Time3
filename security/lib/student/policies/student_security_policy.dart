// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'student_security_limits.dart';

/// Políticas, whitelists regimentais e regras de restrição de segurança para o Aluno.
abstract final class StudentSecurityPolicy {
  StudentSecurityPolicy._();

  // ─── EXTENSÕES AUTORIZADAS PARA SUBMISSÃO DE TAREFAS ───
  /// Extensões de arquivos expressamente autorizadas para entrega de atividades acadêmicas.
  static const Set<String> allowedDeliveryExtensions = {
    // Documentos e Relatórios
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'md',
    // Arquivos Compactados
    'zip', 'rar', '7z', 'tar', 'gz',
    // Código-Fonte e Dados Técnicos
    'c', 'cpp', 'cs', 'java', 'py', 'dart', 'ts', 'js', 'json', 'sql', 'html', 'css',
  };

  // ─── EXTENSÕES AUTORIZADAS PARA PROTOCOLOS DE SECRETARIA ───
  /// Extensões restritas e seguras para documentos comprobatórios direcionados à Secretaria Geral.
  /// Rejeita sumariamente SVG e formatos com suporte a scripts.
  static const Set<String> allowedProtocolExtensions = {
    'pdf',
    'png',
    'jpg',
    'jpeg',
  };

  // ─── EXTENSÕES PERIGOSAS E SUMARIAMENTE BLOQUEADAS ───
  /// Extensões de arquivos executáveis, scripts ou com vetores intrínsecos de XSS/RCE.
  static const Set<String> blockedDangerousExtensions = {
    // Executáveis e Binários de Sistema
    'exe', 'bat', 'cmd', 'sh', 'bash', 'msi', 'com', 'vbs', 'ps1', 'bin', 'dll', 'so',
    // Scripts Web Server-Side
    'php', 'phtml', 'php3', 'php4', 'php5', 'phps', 'cgi', 'pl', 'jsp', 'asp', 'aspx',
    // Vetores de Stored XSS e Manipulação XML
    'svg', 'xhtml', 'xml', 'hta', 'htm',
    // Pacotes Executáveis e Mobile
    'jar', 'apk', 'app', 'deb', 'rpm',
  };

  // ─── HOSTS AUTORIZADOS PARA REPOSITÓRIOS GIT ───
  /// Domínios oficiais e homologados para links de repositório Git.
  static const Set<String> trustedGitHosts = {
    'github.com',
    'gitlab.com',
    'bitbucket.org',
    'gitlab.puc-campinas.edu.br',
  };

  /// Limites numéricos atrelados
  static const limits = StudentSecurityLimits;
}
