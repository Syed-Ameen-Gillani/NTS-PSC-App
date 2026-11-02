import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/data/supabase_teacher_insights_repository.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/domain/repositories/teacher_insights_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final teacherInsightsRepositoryProvider = Provider<TeacherInsightsRepository>(
  (ref) => AppConfig.isSupabaseEnabled
      ? SupabaseTeacherInsightsRepository(Supabase.instance.client)
      : const _TestTeacherInsightsRepository(),
);

final teacherFinancialOverviewProvider =
    FutureProvider.autoDispose<TeacherFinancialOverview>((ref) async {
      if (AppConfig.isSupabaseEnabled) {
        final auth = await ref.watch(authControllerProvider.future);
        if (auth.user == null) return const TeacherFinancialOverview();
      }
      return ref.read(teacherInsightsRepositoryProvider).getFinancialOverview();
    });

class _TestTeacherInsightsRepository implements TeacherInsightsRepository {
  const _TestTeacherInsightsRepository();

  @override
  Future<TeacherDashboardOverview> getDashboardOverview() async =>
      const TeacherDashboardOverview(totalStudents: 1240, activeCourses: 4);

  @override
  Future<TeacherFinancialOverview> getFinancialOverview() async =>
      const TeacherFinancialOverview();

  @override
  Future<List<TeacherLearnerEnrollment>> getLearnerRoster({
    required int limit,
    required int offset,
    String? query,
    String? courseId,
  }) async => const [];
}
