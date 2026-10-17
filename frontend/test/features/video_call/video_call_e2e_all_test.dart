// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';

import 'tier1_category_partition/chat_messaging_partition_test.dart' as t1_chat;
import 'tier1_category_partition/emoji_reaction_partition_test.dart' as t1_emoji;
import 'tier1_category_partition/hand_raise_partition_test.dart' as t1_hand;
import 'tier1_category_partition/lobby_input_validation_test.dart' as t1_lobby;
import 'tier2_boundary_value_analysis/audio_level_threshold_test.dart' as t2_audio;
import 'tier2_boundary_value_analysis/grid_boundary_test.dart' as t2_grid;
import 'tier2_boundary_value_analysis/input_length_boundary_test.dart' as t2_length;
import 'tier2_boundary_value_analysis/recording_timer_boundary_test.dart' as t2_rec;
import 'tier3_pairwise_combinations/media_controls_pairwise_test.dart' as t3_media;
import 'tier3_pairwise_combinations/multi_peer_state_pairwise_test.dart' as t3_peer;
import 'tier4_real_world_scenarios/full_classroom_lecture_e2e_test.dart' as t4_lecture;
import 'tier4_real_world_scenarios/interactive_study_group_e2e_test.dart' as t4_study;
import 'tier4_real_world_scenarios/unexpected_disconnect_recovery_e2e_test.dart' as t4_disconnect;
import 'presentation/production_presentation_test.dart' as prod_pres;
import 'tier4_real_world_scenarios/zero_bots_multi_user_e2e_test.dart' as t4_zero_bots;

/// Master test runner for the complete 4-tier P2P Video Conferencing test suite.
void main() {
  group('P2P Video Conferencing — Comprehensive 4-Tier Opaque-Box Test Suite', () {
    group('Tier 1: Category-Partition (Equivalence Classes)', () {
      t1_lobby.main();
      t1_chat.main();
      t1_emoji.main();
      t1_hand.main();
    });

    group('Tier 2: Boundary Value Analysis (BVA)', () {
      t2_grid.main();
      t2_audio.main();
      t2_length.main();
      t2_rec.main();
    });

    group('Tier 3: Pairwise Combinations (N x M Matrices)', () {
      t3_media.main();
      t3_peer.main();
    });

    group('Tier 4: Real-World Scenarios (End-to-End Workflows)', () {
      t4_zero_bots.main();
      t4_lecture.main();
      t4_study.main();
      t4_disconnect.main();
    });

    group('Production Presentation Layer Verification', () {
      prod_pres.main();
    });
  });
}
