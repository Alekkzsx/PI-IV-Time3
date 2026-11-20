// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// [widgets.dart]
///
/// Arquivo barril (barrel) central que exporta todos os componentes do módulo de Disciplinas:
/// catálogo e estatísticas, cockpit do AVA (abas, sidebars, seções), grade horária e diálogos modais.
library;

// Catalog
export 'catalog/disciplines_grid_view.dart';
export 'catalog/disciplines_list_view.dart';
export 'catalog/disciplines_stats_card.dart';
export 'catalog/fast_resume_card.dart';

// Modals
export 'modals/disciplines_modals.dart';

// AVA Cockpit
export 'ava/common/ava_common.dart';
export 'ava/tabs/ava_tabs.dart';
export 'ava/ava_section_card.dart';
export 'ava/ava_left_sidebar.dart';
export 'ava/ava_right_sidebar.dart';
export 'ava/ava_home_tab.dart';
export 'ava/ava_syllabus_materials_tab.dart';
export 'ava/ava_live_classroom_tab.dart';
export 'ava/ava_assignments_tab.dart';
export 'ava/ava_evaluations_grades_tab.dart';
export 'ava/ava_forum_collaboration_tab.dart';

// Schedule & Support
export 'schedule/schedule_card.dart';
export 'schedule/disciplines_schedule_table.dart';
export 'schedule/upcoming_deliveries_card.dart';
export 'schedule/discipline_notices_card.dart';
export 'schedule/academic_support_card.dart';
