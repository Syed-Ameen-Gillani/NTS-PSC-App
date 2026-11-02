import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';

typedef TeacherQuizSummary = ({int attempts, double averagePercent});

final teacherQuizSummaryProvider = FutureProvider.autoDispose
    .family<TeacherQuizSummary, String>((ref, quizId) async {
      final repository = ref.read(quizRepositoryProvider);
      if (repository is! SupabaseQuizRepository) {
        throw StateError('Quiz analysis requires live data.');
      }
      return repository.getTeacherQuizSummary(quizId);
    });
