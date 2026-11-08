// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

part of '../portal_controller.dart';

/// [_PortalBridgeMixin]
///
/// Mixin de domínio responsável pela escuta e sincronização reativa em tempo real
/// com o barramento multiperfil [AcademicBridgeService] (publicação de atividades,
/// lançamento de notas, homologação de frequência e pareceres de protocolos).
mixin _PortalBridgeMixin on _PortalControllerBase {
  /// Inicializa os ouvintes reativos do [AcademicBridgeService] para sincronização multiperfil em tempo real.
  void _initAcademicBridgeListener() {
    AcademicBridgeService.instance.onStudentDataChanged = () {
      notifyListeners();
    };

    AcademicBridgeService.instance.onAssignmentPublishedToStudent =
        (delivery, event) {
          deliveries.insert(
            0,
            StudentDeliveryItem(
              id: delivery.id,
              sourceAssignmentId: delivery.sourceAssignmentId,
              title: delivery.title,
              disciplineCode: delivery.disciplineCode,
              disciplineName: delivery.disciplineName,
              dueDate: delivery.dueDate,
              dueHour: delivery.dueHour,
              status: delivery.status,
              weight: delivery.weight,
              score: delivery.score,
              feedback: delivery.feedback,
              protocol: delivery.protocol,
              rubrics: delivery.rubrics,
              activityCode: delivery.activityCode,
              description: delivery.description,
              professor: delivery.professor,
              deadlineBadge: delivery.deadlineBadge,
              isUrgent: delivery.isUrgent,
              allowedFormats: delivery.allowedFormats,
              submissionDate: delivery.submissionDate,
              feedbackDate: delivery.feedbackDate,
              maxScore: delivery.maxScore,
              attachmentCount: delivery.attachmentCount,
            ),
          );
          events.insert(
            0,
            StudentCalendarEvent(
              id: event.id,
              title: event.title,
              date: event.date,
              time: event.time,
              type: event.type,
              discipline: event.discipline,
              location: event.location,
            ),
          );

          final discIdx = disciplines.indexWhere(
            (d) => d.code == delivery.disciplineCode,
          );
          if (discIdx != -1) {
            final oldDisc = disciplines[discIdx];
            disciplines[discIdx] = StudentDisciplineModel(
              code: oldDisc.code,
              fullCode: oldDisc.fullCode,
              name: oldDisc.name,
              professor: oldDisc.professor,
              time: oldDisc.time,
              location: oldDisc.location,
              progress: oldDisc.progress,
              n1: oldDisc.n1,
              n2: oldDisc.n2,
              p1: oldDisc.p1,
              p2: oldDisc.p2,
              trab: oldDisc.trab,
              partialAverage: oldDisc.partialAverage,
              attendancePercentage: oldDisc.attendancePercentage,
              absences: oldDisc.absences,
              totalHours: oldDisc.totalHours,
              completedHours: oldDisc.completedHours,
              maxAbsenceHours: oldDisc.maxAbsenceHours,
              hasPendingTask: true,
            );
          }
          notifyListeners();
        };

    AcademicBridgeService.instance.onGradedReceivedByStudent =
        (deliveryId, finalScore, feedback, rubrics) {
          final idx = deliveries.indexWhere((d) => d.id == deliveryId);
          if (idx != -1) {
            final old = deliveries[idx];
            deliveries[idx] = StudentDeliveryItem(
              id: old.id,
              sourceAssignmentId: old.sourceAssignmentId,
              activityCode: old.activityCode,
              title: old.title,
              disciplineCode: old.disciplineCode,
              disciplineName: old.disciplineName,
              description: old.description,
              dueDate: old.dueDate,
              dueHour: old.dueHour,
              deadlineBadge: 'Corrigida • Nota Homologada',
              isUrgent: false,
              professor: old.professor,
              allowedFormats: old.allowedFormats,
              submissionDate: old.submissionDate,
              status: 'Avaliada',
              weight: old.weight,
              maxScore: old.maxScore,
              score: finalScore,
              feedback: feedback,
              protocol: old.protocol,
              attachmentCount: old.attachmentCount,
              rubrics: rubrics
                  .map(
                    (r) => {
                      'id': r.id,
                      'title': r.title,
                      'maxPoints': r.maxPoints,
                      'assignedScore': r.assignedScore,
                      'description': r.description,
                    },
                  )
                  .toList(),
            );

            final discIdx = disciplines.indexWhere(
              (d) => d.code == old.disciplineCode,
            );
            if (discIdx != -1) {
              final oldDisc = disciplines[discIdx];
              final newAverage = double.parse(
                ((finalScore * 0.4 + oldDisc.p2 * 0.4 + oldDisc.trab * 0.2))
                    .toStringAsFixed(1),
              );
              disciplines[discIdx] = StudentDisciplineModel(
                code: oldDisc.code,
                fullCode: oldDisc.fullCode,
                name: oldDisc.name,
                professor: oldDisc.professor,
                time: oldDisc.time,
                location: oldDisc.location,
                progress: oldDisc.progress,
                n1: finalScore,
                n2: oldDisc.n2,
                p1: finalScore,
                p2: oldDisc.p2,
                trab: oldDisc.trab,
                partialAverage: newAverage,
                attendancePercentage: oldDisc.attendancePercentage,
                absences: oldDisc.absences,
                totalHours: oldDisc.totalHours,
                completedHours: oldDisc.completedHours,
                maxAbsenceHours: oldDisc.maxAbsenceHours,
                hasPendingTask: false,
              );
            }
            notifyListeners();
          }
        };

    AcademicBridgeService
        .instance
        .onAttendanceHomologated = (courseCode, sessionDate, attendances) {
      final discIdx = disciplines.indexWhere(
        (d) =>
            d.code.toUpperCase() == courseCode.toUpperCase() ||
            (d.fullCode != null &&
                d.fullCode!.toUpperCase().contains(courseCode.toUpperCase())),
      );

      if (discIdx != -1) {
        final oldDisc = disciplines[discIdx];
        Map<String, dynamic>? myRecord;
        for (final a in attendances) {
          if (a['ra']?.toString() == AppUserSession.instance.identity) {
            myRecord = a;
            break;
          }
        }
        if (myRecord == null) return;

        final status = myRecord['status'] as String? ?? 'presente';
        int newAbsences = oldDisc.absences;
        int newCompletedHours = oldDisc.completedHours + 2;

        if (status == 'ausente') {
          newAbsences += 2;
        }

        final rate =
            ((newCompletedHours - newAbsences) / newCompletedHours * 100).clamp(
              0.0,
              100.0,
            );
        final newAttendancePercentage = double.parse(rate.toStringAsFixed(1));

        disciplines[discIdx] = StudentDisciplineModel(
          code: oldDisc.code,
          fullCode: oldDisc.fullCode,
          name: oldDisc.name,
          professor: oldDisc.professor,
          time: oldDisc.time,
          location: oldDisc.location,
          progress: (newCompletedHours / oldDisc.totalHours).clamp(0.0, 1.0),
          n1: oldDisc.n1,
          n2: oldDisc.n2,
          p1: oldDisc.p1,
          p2: oldDisc.p2,
          trab: oldDisc.trab,
          partialAverage: oldDisc.partialAverage,
          attendancePercentage: newAttendancePercentage,
          absences: newAbsences,
          totalHours: oldDisc.totalHours,
          completedHours: newCompletedHours,
          maxAbsenceHours: oldDisc.maxAbsenceHours,
          hasPendingTask: oldDisc.hasPendingTask,
        );

        if (selectedDiscipline?.code == oldDisc.code) {
          selectedDiscipline = disciplines[discIdx];
        }

        notifyListeners();
      }
    };

    AcademicBridgeService.instance.onStudentProtocolUpdated =
        (protocolCode, isApproved, decisionNote, approverName) {
          if (isApproved &&
              (protocolCode.contains('MED') ||
                  decisionNote.toLowerCase().contains('abono') ||
                  decisionNote.toLowerCase().contains('falta') ||
                  decisionNote.toLowerCase().contains('atestado'))) {
            final discIdx = disciplines.indexWhere((d) => d.code == 'APS-II');
            if (discIdx != -1) {
              final oldDisc = disciplines[discIdx];
              final newAbsences = (oldDisc.absences - 2).clamp(0, 100);
              final rate =
                  ((oldDisc.completedHours - newAbsences) /
                          oldDisc.completedHours *
                          100)
                      .clamp(0.0, 100.0);
              disciplines[discIdx] = StudentDisciplineModel(
                code: oldDisc.code,
                fullCode: oldDisc.fullCode,
                name: oldDisc.name,
                professor: oldDisc.professor,
                time: oldDisc.time,
                location: oldDisc.location,
                progress: oldDisc.progress,
                n1: oldDisc.n1,
                n2: oldDisc.n2,
                p1: oldDisc.p1,
                p2: oldDisc.p2,
                trab: oldDisc.trab,
                partialAverage: oldDisc.partialAverage,
                attendancePercentage: double.parse(rate.toStringAsFixed(1)),
                absences: newAbsences,
                totalHours: oldDisc.totalHours,
                completedHours: oldDisc.completedHours,
                maxAbsenceHours: oldDisc.maxAbsenceHours,
                hasPendingTask: oldDisc.hasPendingTask,
              );
              if (selectedDiscipline?.code == oldDisc.code) {
                selectedDiscipline = disciplines[discIdx];
              }
              notifyListeners();
            }
          }
        };
  }
}
