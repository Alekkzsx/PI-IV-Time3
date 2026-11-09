// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Agenda de Eventos e Comunicados Acadêmicos

part of '../docente_controller.dart';

mixin _DocenteAgendaNoticesMixin on _DocenteControllerBase {
  Future<void> addEvent({
    required String title,
    required String date,
    required String time,
    required EventType type,
    required String location,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_calendar') ||
        title.trim().isEmpty) {
      return;
    }
    try {
      await _remote.createEvent(
        title: title.trim(),
        date: date,
        time: time,
        type: type.name,
        location: location.trim(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar o evento.';
    }
    notifyListeners();
  }

  Future<bool> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required NoticeClassification classification,
    required String title,
    required String message,
  }) async {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission(
          'publish_course_announcements',
        ) ||
        title.trim().isEmpty ||
        message.trim().isEmpty) {
      return false;
    }
    final normalizedTargetCourse = targetCourse.trim().toLowerCase();
    final recipientCourse = _courses.where((course) {
      return course.id.toLowerCase() == normalizedTargetCourse ||
          course.code.toLowerCase() == normalizedTargetCourse ||
          course.title.toLowerCase() == normalizedTargetCourse;
    }).firstOrNull;
    if (recipientCourse == null ||
        !_courses.any((course) => course.id == recipientCourse.id)) {
      return false;
    }
    try {
      await _remote.publishNotice(
        targetCourse: recipientCourse.code,
        targetAudience: targetAudience.trim(),
        classification: classification.name,
        title: title.trim(),
        message: message.trim(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      remoteError = 'Não foi possível publicar o comunicado.';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>?> getNoticeReads(String id) async {
    try {
      return await _remote.noticeReads(id);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
    return null;
  }

  void notificarAlunoInfrequencia(String studentId, String studentName) {
    if (!_canManageCourse(_selectedCourseId, 'publish_course_announcements')) {
      return;
    }
    publishNotice(
      targetCourse: selectedCourse.title,
      targetAudience: 'Discente: $studentName ($studentId)',
      classification: NoticeClassification.urgencia,
      title: 'Alerta Preventivo de Infrequência - Assiduidade Regimental',
      message:
          'Prezado(a) $studentName, identificamos que seu percentual de frequência na disciplina ${selectedCourse.title} atingiu o limite crítico regimental. Por gentileza, procure a docente durante o plantão de dúvidas ou regularize eventuais faltas com atestados perante a Secretaria Geral.',
    );
  }
}
