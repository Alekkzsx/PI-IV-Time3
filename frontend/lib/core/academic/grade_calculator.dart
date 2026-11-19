/// Espelho frontend dos parâmetros regimentais configurados em `admin_settings`.
class AcademicThresholds {
  final double minimumGrade;
  final double minimumAttendance;
  final double specialExamGrade;
  final String evaluationFormula;
  final String resolutionCode;
  final String currentSemesterLabel;
  final String currentWeekLabel;

  static const AcademicThresholds defaults = AcademicThresholds();

  const AcademicThresholds({
    this.minimumGrade = 6.0,
    this.minimumAttendance = 75.0,
    this.specialExamGrade = 4.0,
    this.evaluationFormula = '(N1 × 0.4) + (N2 × 0.6)',
    this.resolutionCode = 'RESOLUÇÃO CONSEPE 2026/04',
    this.currentSemesterLabel = '2026/2',
    this.currentWeekLabel = 'Calendário Vigente 2026/2',
  });

  factory AcademicThresholds.fromJson(Object? raw) {
    if (raw is! Map) return AcademicThresholds.defaults;
    final map = Map<String, dynamic>.from(raw);
    double numVal(Object? v, double fallback) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String strVal(Object? v, String fallback) {
      final text = v?.toString().trim() ?? '';
      return text.isEmpty ? fallback : text;
    }

    return AcademicThresholds(
      minimumGrade: numVal(map['minimumGrade'] ?? map['passingGrade'], 6.0),
      minimumAttendance: numVal(map['minimumAttendance'], 75.0),
      specialExamGrade: numVal(map['specialExamGrade'], 4.0),
      evaluationFormula: strVal(
        map['evaluationFormula'] ?? map['defaultFormula'],
        '(N1 × 0.4) + (N2 × 0.6)',
      ),
      resolutionCode: strVal(
        map['resolutionCode'],
        'RESOLUÇÃO CONSEPE 2026/04',
      ),
      currentSemesterLabel: strVal(
        map['currentSemesterLabel'] ?? map['academicPeriod'],
        '2026/2',
      ),
      currentWeekLabel: strVal(
        map['currentWeekLabel'],
        'Calendário Vigente 2026/2',
      ),
    );
  }
}

enum GradeFormulaMode { ponderada, equitativa, aritmetica }

class GradeFormulaSpec {
  final GradeFormulaMode mode;
  final double n1Weight;
  final double n2Weight;

  const GradeFormulaSpec({
    required this.mode,
    required this.n1Weight,
    required this.n2Weight,
  });
}

/// Motor compartilhado de cálculo de médias conforme fórmula regimental da turma.
class GradeCalculator {
  const GradeCalculator._();

  static GradeFormulaSpec parseFormula(String? rawFormula) {
    final raw = (rawFormula ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('aritm') ||
        lower.contains('contínu') ||
        lower.contains('continu') ||
        lower.contains('/ 4') ||
        lower.contains('/4')) {
      return const GradeFormulaSpec(
        mode: GradeFormulaMode.aritmetica,
        n1Weight: 0.5,
        n2Weight: 0.5,
      );
    }

    if (lower.contains('equitativa') ||
        lower.contains('/ 2') ||
        lower.contains('/2')) {
      return const GradeFormulaSpec(
        mode: GradeFormulaMode.equitativa,
        n1Weight: 0.5,
        n2Weight: 0.5,
      );
    }

    final normalized = raw.replaceAll(',', '.');
    final n1Match = RegExp(
      r'N1\s*[×*x]\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(normalized);
    final n2Match = RegExp(
      r'N2\s*[×*x]\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (n1Match != null && n2Match != null) {
      final w1 = double.tryParse(n1Match.group(1) ?? '');
      final w2 = double.tryParse(n2Match.group(1) ?? '');
      if (w1 != null && w2 != null && (w1 + w2) > 0) {
        final total = w1 + w2;
        final rw1 = w1 / total;
        final rw2 = w2 / total;
        return GradeFormulaSpec(
          mode: (rw1 - 0.5).abs() < 0.001
              ? GradeFormulaMode.equitativa
              : GradeFormulaMode.ponderada,
          n1Weight: rw1,
          n2Weight: rw2,
        );
      }
    }

    if (lower.contains('50%') && lower.contains('n1') && lower.contains('n2')) {
      return const GradeFormulaSpec(
        mode: GradeFormulaMode.equitativa,
        n1Weight: 0.5,
        n2Weight: 0.5,
      );
    }

    return const GradeFormulaSpec(
      mode: GradeFormulaMode.ponderada,
      n1Weight: 0.4,
      n2Weight: 0.6,
    );
  }

  static double _round1(double v) => double.parse(v.toStringAsFixed(1));

  static double computeN1(
    double assignmentsScore,
    double p1Score, {
    String? formula,
  }) {
    final spec = parseFormula(formula);
    if (spec.mode == GradeFormulaMode.aritmetica) {
      return _round1((assignmentsScore + p1Score) / 2);
    }
    return _round1((assignmentsScore * 0.4) + (p1Score * 0.6));
  }

  static double computeN2(
    double projectsScore,
    double p2Score, {
    String? formula,
  }) {
    final spec = parseFormula(formula);
    if (spec.mode == GradeFormulaMode.aritmetica) {
      return _round1((projectsScore + p2Score) / 2);
    }
    return _round1((projectsScore * 0.4) + (p2Score * 0.6));
  }

  static double computeFinalAverage({
    required double assignmentsScore,
    required double p1Score,
    required double projectsScore,
    required double p2Score,
    String? formula,
  }) {
    final spec = parseFormula(formula);
    if (spec.mode == GradeFormulaMode.aritmetica) {
      return _round1((assignmentsScore + p1Score + projectsScore + p2Score) / 4);
    }
    final n1 = computeN1(assignmentsScore, p1Score, formula: formula);
    final n2 = computeN2(projectsScore, p2Score, formula: formula);
    return _round1((n1 * spec.n1Weight) + (n2 * spec.n2Weight));
  }
}
