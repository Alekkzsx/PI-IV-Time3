// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

part of '../portal_controller.dart';

/// [_PortalDeliveriesMixin]
///
/// Mixin de domínio responsável pelo filtro de atividades, submissão de entregas
/// com protocolo e transferência/download de materiais, submissões e requerimentos.
mixin _PortalDeliveriesMixin on _PortalControllerBase {
  /// Modifica o filtro de visualização das entregas acadêmicas.
  ///
  /// Parâmetros:
  /// - [filter]: Nome do filtro selecionado (ex.: 'Todas', 'Pendentes', 'Enviadas').
  void setDeliveryFilter(String filter) {
    activeDeliveryFilter = filter;
    notifyListeners();
  }

  /// Realiza a submissão formal de uma entrega de trabalho acadêmico.
  ///
  /// Parâmetros:
  /// - [deliveryId]: Identificador da atividade a ser entregue.
  /// - [fileName]: Nome do arquivo digital anexado.
  /// - [fileSize]: Tamanho textual do arquivo.
  /// - [mimeType]: Tipo MIME correspondente.
  /// - [contentBase64]: Conteúdo em Base64 do arquivo binário.
  /// - [gitUrl]: URL opcional para repositório Git associado.
  /// - [comments]: Observações explicativas para a banca avaliadora.
  ///
  /// Retorna o mapa de resposta retornado pela API REST.
  Future<Map<String, dynamic>> submitDelivery({
    required String deliveryId,
    required String fileName,
    required String fileSize,
    required String mimeType,
    required String contentBase64,
    String? gitUrl,
    String? comments,
  }) async {
    if (!AppUserSession.instance.hasRole('aluno')) {
      throw const ApiException('Apenas alunos podem enviar atividades.');
    }
    final response = await _remote.submitDelivery(
      assignmentId: deliveryId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      contentBase64: contentBase64,
      gitUrl: gitUrl,
      comments: comments,
    );
    final protocol = response['protocolCode'];
    if (protocol is! String || protocol.isEmpty) {
      throw const ApiException('A API não retornou o protocolo da entrega.');
    }
    final deliveryIndex = deliveries.indexWhere(
      (delivery) =>
          delivery.id == deliveryId ||
          delivery.sourceAssignmentId == deliveryId,
    );
    if (deliveryIndex != -1) {
      final delivery = deliveries[deliveryIndex];
      final session = AppUserSession.instance;
      AcademicBridgeService.instance.notifySubmissionToDocente(
        deliveryId: delivery.id,
        assignmentId: delivery.sourceAssignmentId ?? deliveryId,
        courseCode: delivery.disciplineCode,
        studentName: session.effectiveName,
        studentRa: session.identity ?? '',
        fileName: fileName,
        protocol: protocol,
        comments: comments,
      );
    }
    await loadRemote(force: true);
    return response;
  }

  /// Realiza o download seguro e armazenamento em disco de um material didático.
  ///
  /// Parâmetros:
  /// - [material]: Modelo do material a ser baixado.
  ///
  /// Retorna o caminho de armazenamento do arquivo salvo, ou nulo se cancelado.
  Future<String?> downloadMaterial(StudentMaterialItem material) async {
    final response = await _remote.downloadMaterial(material.id);
    return _saveDownloadedFile(response, material.fileName, material.fileType);
  }

  /// Baixa o arquivo anexado em uma submissão prévia do estudante.
  ///
  /// Parâmetros:
  /// - [id]: Identificador da submissão discente.
  Future<String?> downloadSubmission(String id) async {
    final response = await _remote.downloadSubmission(id);
    return _saveDownloadedFile(
      response,
      response['fileName']?.toString() ?? 'submissao.txt',
      'application/octet-stream',
    );
  }

  /// Realiza o download de documentos comprobatórios anexados a um protocolo.
  ///
  /// Parâmetros:
  /// - [id]: Identificador do requerimento na secretaria virtual.
  Future<String?> downloadProtocol(String id) async {
    final response = await _remote.downloadProtocol(id);
    return _saveDownloadedFile(
      response,
      response['attachmentName']?.toString() ?? 'protocolo.txt',
      'text/plain',
    );
  }

  /// Salva em disco ou aciona o download via navegador utilizando o helper multiplataforma.
  Future<String?> _saveDownloadedFile(
    Map<String, dynamic> response,
    String fileName,
    String mimeType,
  ) {
    return PlatformFileHelper.saveOrDownloadFile(
      fileName: fileName,
      bytes: _remote.decodeFileContent(response),
      mimeType: mimeType,
    );
  }
}
