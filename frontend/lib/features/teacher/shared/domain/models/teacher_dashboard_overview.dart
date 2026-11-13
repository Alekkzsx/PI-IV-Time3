// Desenvolvido por Time 3 - PI IV
// Modelos imutáveis do Painel Geral do Portal Docente (dados 100% vindos do backend/MongoDB)

class TeacherHeroInfo {
  final String greetingPrefix;
  final String firstName;
  final String department;
  final String semester;

  const TeacherHeroInfo({
    required this.greetingPrefix,
    required this.firstName,
    required this.department,
    required this.semester,
  });

  static const TeacherHeroInfo empty = TeacherHeroInfo(
    greetingPrefix: '',
    firstName: '',
    department: '',
    semester: '',
  );
}

class TeacherDashboardKpiItem {
  final String label;
  final String valueFormatted;
  final String unitLabel;
  final String footerLabel;
  final String footerValue;
  final double progress;

  const TeacherDashboardKpiItem({
    required this.label,
    required this.valueFormatted,
    required this.unitLabel,
    required this.footerLabel,
    required this.footerValue,
    required this.progress,
  });

  static const TeacherDashboardKpiItem empty = TeacherDashboardKpiItem(
    label: '',
    valueFormatted: '00',
    unitLabel: '',
    footerLabel: '',
    footerValue: '',
    progress: 0.0,
  );
}

class TeacherDashboardStats {
  final TeacherDashboardKpiItem activeClasses;
  final TeacherDashboardKpiItem monthlyAssignments;
  final TeacherDashboardKpiItem workload;
  final TeacherDashboardKpiItem averageAttendance;

  const TeacherDashboardStats({
    required this.activeClasses,
    required this.monthlyAssignments,
    required this.workload,
    required this.averageAttendance,
  });

  static const TeacherDashboardStats empty = TeacherDashboardStats(
    activeClasses: TeacherDashboardKpiItem.empty,
    monthlyAssignments: TeacherDashboardKpiItem.empty,
    workload: TeacherDashboardKpiItem.empty,
    averageAttendance: TeacherDashboardKpiItem.empty,
  );
}

class TeacherLiveSessionPreview {
  final String courseId;
  final String code;
  final String roomCode;
  final String title;
  final String timeRange;
  final bool isLive;
  final String statusLabel;
  final int connectedCount;
  final String connectedLabel;
  final String locationLabel;
  final String buttonLabel;

  const TeacherLiveSessionPreview({
    required this.courseId,
    required this.code,
    required this.roomCode,
    required this.title,
    required this.timeRange,
    required this.isLive,
    required this.statusLabel,
    required this.connectedCount,
    required this.connectedLabel,
    required this.locationLabel,
    required this.buttonLabel,
  });
}

class TeacherOfficeHoursInfo {
  final String title;
  final String subtitle;
  final String location;

  const TeacherOfficeHoursInfo({
    required this.title,
    required this.subtitle,
    required this.location,
  });

  static const TeacherOfficeHoursInfo empty = TeacherOfficeHoursInfo(
    title: '',
    subtitle: '',
    location: '',
  );
}

class TeacherTodayClassInfo {
  final String todayBadge;
  final TeacherLiveSessionPreview? session;
  final TeacherOfficeHoursInfo officeHours;

  const TeacherTodayClassInfo({
    required this.todayBadge,
    required this.session,
    required this.officeHours,
  });

  static const TeacherTodayClassInfo empty = TeacherTodayClassInfo(
    todayBadge: '',
    session: null,
    officeHours: TeacherOfficeHoursInfo.empty,
  );
}

class TeacherDeadlinePreviewItem {
  final String id;
  final String courseId;
  final String typeLabel;
  final String displayTitle;
  final String courseName;
  final String dueLabel;
  final bool isUrgent;

  const TeacherDeadlinePreviewItem({
    required this.id,
    required this.courseId,
    required this.typeLabel,
    required this.displayTitle,
    required this.courseName,
    required this.dueLabel,
    required this.isUrgent,
  });
}

class TeacherUpcomingDeadlines {
  final String totalCountFormatted;
  final List<TeacherDeadlinePreviewItem> items;

  const TeacherUpcomingDeadlines({
    required this.totalCountFormatted,
    required this.items,
  });

  static const TeacherUpcomingDeadlines empty = TeacherUpcomingDeadlines(
    totalCountFormatted: '00',
    items: [],
  );
}

class TeacherNoticePreviewItem {
  final String id;
  final String authorLabel;
  final String timeLabel;
  final String title;
  final String message;

  const TeacherNoticePreviewItem({
    required this.id,
    required this.authorLabel,
    required this.timeLabel,
    required this.title,
    required this.message,
  });
}

class TeacherDashboardOverview {
  final TeacherHeroInfo hero;
  final TeacherDashboardStats stats;
  final TeacherTodayClassInfo todayClass;
  final TeacherUpcomingDeadlines upcomingDeadlines;
  final List<TeacherNoticePreviewItem> recentNotices;

  const TeacherDashboardOverview({
    required this.hero,
    required this.stats,
    required this.todayClass,
    required this.upcomingDeadlines,
    required this.recentNotices,
  });

  static const TeacherDashboardOverview empty = TeacherDashboardOverview(
    hero: TeacherHeroInfo.empty,
    stats: TeacherDashboardStats.empty,
    todayClass: TeacherTodayClassInfo.empty,
    upcomingDeadlines: TeacherUpcomingDeadlines.empty,
    recentNotices: [],
  );
}
