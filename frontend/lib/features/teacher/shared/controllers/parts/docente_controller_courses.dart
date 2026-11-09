// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Turmas, Ementa, Materiais e Fórum

part of '../docente_controller.dart';

mixin _DocenteCoursesMixin on _DocenteControllerBase {
  Future<void> advanceSyllabusClasses(String courseId, String unitId) async {
    if (!_canManageCourse(courseId, 'manage_course_content')) return;
    try {
      await _remote.advanceSyllabus(selectedCourse.code, unitId);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível avançar o plano de ensino.';
    }
    notifyListeners();
  }

  Future<void> publishMaterial(
    String courseId,
    String title,
    PickedPlatformFile? file,
  ) async {
    if (!_canManageCourse(courseId, 'manage_materials') ||
        title.trim().isEmpty ||
        file == null ||
        file.sizeBytes > 25 * 1024 * 1024) {
      if (file == null) remoteError = 'Selecione um arquivo para publicar.';
      if (file != null && file.sizeBytes > 25 * 1024 * 1024) {
        remoteError = 'O arquivo deve ter no máximo 25 MB.';
      }
      notifyListeners();
      return;
    }
    try {
      await _remote.publishMaterial(
        classCode: selectedCourse.code,
        title: title.trim(),
        fileName: file.name,
        mimeType: file.mimeType,
        size: file.sizeLabel,
        contentBase64: file.base64Content,
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível publicar o material.';
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> get currentForumTopics =>
      List.unmodifiable(selectedCourse.forumTopics);

  Future<bool> createForumTopic({
    required String title,
    required String body,
    String? category,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content') ||
        title.trim().isEmpty ||
        body.trim().isEmpty) {
      return false;
    }
    try {
      await _remote.createForumTopic(
        classCode: selectedCourse.code,
        title: title.trim(),
        body: body.trim(),
        category: category,
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível criar o tópico.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> replyForumTopic({
    required String topicId,
    required String body,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content') ||
        body.trim().isEmpty) {
      return false;
    }
    try {
      await _remote.replyForumTopic(
        classCode: selectedCourse.code,
        topicId: topicId,
        body: body.trim(),
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível responder no fórum.';
    }
    notifyListeners();
    return false;
  }

  Future<void> saveSquads(List<Map<String, Object?>> squads) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content')) return;
    try {
      await _remote.saveSquads(classCode: selectedCourse.code, squads: squads);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar as equipes.';
    }
    notifyListeners();
  }
}
