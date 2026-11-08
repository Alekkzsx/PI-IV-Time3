// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// [MaterialItem]
///
/// Representa um recurso didático ou arquivo disponibilizado para download
/// aos alunos matriculados em uma disciplina curricular.
class MaterialItem {
  /// Identificador exclusivo do recurso pedagógico.
  final String id;

  /// Código da disciplina à qual o material está vinculado.
  final String courseCode;

  /// Título de exibição amigável do arquivo/material.
  final String title;

  /// Nome real do arquivo no sistema de arquivos ou storage remoto.
  final String fileName;

  /// Data em que o material foi publicado pelo professor.
  final String date;

  /// Tamanho formatado do arquivo (ex.: '2.4 MB', '500 KB').
  final String size;

  /// Extensão ou tipo mime representativo (ex.: 'PDF', 'ZIP', 'MP4').
  final String fileType;

  /// Módulo ou unidade pedagógica à qual o conteúdo se associa.
  final String unitAssociated;

  /// Categoria ou selo editorial do arquivo (ex.: 'INSTITUCIONAL', 'SLIDES DE AULA').
  final String? category;

  /// URL relativa ou absoluta para requisição e download seguro do arquivo.
  final String downloadUrl;

  /// Cria uma nova instância imutável de [MaterialItem].
  const MaterialItem({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.fileName,
    required this.date,
    required this.size,
    required this.fileType,
    this.unitAssociated = 'Unidade 1',
    this.category,
    this.downloadUrl = '',
  });

  /// Instancia [MaterialItem] a partir de um mapa de dados serializado em JSON.
  ///
  /// Parâmetros:
  /// - [json]: Mapa contendo os atributos retornados pelo serviço de conteúdo.
  ///
  /// Executa:
  /// 1. Extração do identificador com validação de string não nula.
  /// 2. Resolução do nome do arquivo com fallback para o próprio título.
  /// 3. Normalização da extensão para letras maiúsculas.
  /// 4. Inferência do endpoint de download padronizado `/api/files/materials/{id}` caso não informado.
  ///
  /// Retorna o modelo pedagógico devidamente populado.
  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    return MaterialItem(
      id: id,
      courseCode: json['courseCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      fileType:
          (json['fileType'] ?? json['type'])?.toString().toUpperCase() ?? 'PDF',
      unitAssociated: json['unitAssociated']?.toString() ?? '',
      category: json['category']?.toString(),
      downloadUrl:
          json['downloadUrl']?.toString() ??
          (id.isNotEmpty ? '/api/files/materials/$id' : ''),
    );
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentMaterialItem = MaterialItem;
