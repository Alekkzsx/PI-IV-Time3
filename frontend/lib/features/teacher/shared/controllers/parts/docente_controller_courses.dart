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
    PickedPlatformFile? file, {
    String? unitAssociated,
    String? category,
  }) async {
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
      final course = _courses.firstWhere((c) => c.id == courseId);
      await _remote.publishMaterial(
        classCode: course.code,
        title: title.trim(),
        fileName: file.name,
        mimeType: file.mimeType,
        size: file.sizeLabel,
        contentBase64: file.base64Content,
        unitAssociated: unitAssociated,
        category: category,
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível publicar o material.';
    }
    notifyListeners();
  }

  Future<bool> deleteMaterial(String courseId, String materialId) async {
    if (!_canManageCourse(courseId, 'manage_materials')) return false;
    try {
      final course = _courses.firstWhere((c) => c.id == courseId);
      await _remote.deleteMaterial(course.code, materialId);
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível remover o material.';
    }
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> downloadMaterial(String materialId) async {
    if (!_hasActiveTeacherAccess) return null;
    try {
      return await _remote.downloadMaterial(materialId);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível baixar o material.';
    }
    notifyListeners();
    return null;
  }

  Future<bool> updateSyllabusPlan({
    required String courseId,
    String? syllabus,
    String? objectives,
    String? methodology,
    String? evaluationFormula,
    List<Map<String, Object?>>? bibliography,
  }) async {
    if (!_canManageCourse(courseId, 'manage_course_content')) return false;
    try {
      final course = _courses.firstWhere((c) => c.id == courseId);
      await _remote.updateSyllabusPlan(
        classCode: course.code,
        syllabus: syllabus,
        objectives: objectives,
        methodology: methodology,
        evaluationFormula: evaluationFormula,
        bibliography: bibliography,
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível atualizar o plano de ensino.';
    }
    notifyListeners();
    return false;
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

  Future<bool> resolveForumTopic({
    required String topicId,
    required bool isResolved,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content')) {
      return false;
    }
    try {
      await _remote.resolveForumTopic(
        classCode: selectedCourse.code,
        topicId: topicId,
        isResolved: isResolved,
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível atualizar o status do tópico.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> saveSquads(List<Map<String, Object?>> squads) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content')) {
      return false;
    }
    try {
      await _remote.saveSquads(classCode: selectedCourse.code, squads: squads);
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar as equipes.';
    }
    notifyListeners();
    return false;
  }
}
