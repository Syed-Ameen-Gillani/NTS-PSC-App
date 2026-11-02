import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/domain/repositories/teacher_insights_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class _SlowFinance implements TeacherInsightsRepository {
  final finance = Completer<TeacherFinancialOverview>();
  int financeRequests = 0;

  @override
  Future<TeacherDashboardOverview> getDashboardOverview() async =>
      const TeacherDashboardOverview(totalStudents: 2, activeCourses: 1);

  @override
  Future<TeacherFinancialOverview> getFinancialOverview() {
    financeRequests++;
    return finance.future;
  }

  @override
  Future<List<TeacherLearnerEnrollment>> getLearnerRoster({
    required int limit,
    required int offset,
    String? query,
    String? courseId,
  }) async => [];
}

void main() {
  test('studio loads independently of a slow financial request', () async {
    final previousMode = AppConfig.isSupabaseEnabled;
    AppConfig.isSupabaseEnabled = false;
    addTearDown(() => AppConfig.isSupabaseEnabled = previousMode);
    final insights = _SlowFinance();
    final container = ProviderContainer(
      overrides: [
        teacherInsightsRepositoryProvider.overrideWithValue(insights),
      ],
    );
    addTearDown(container.dispose);

    final studio = await container.read(teacherControllerProvider.future);
    expect(studio.stats.totalStudents, 2);
    expect(insights.financeRequests, 0);

    final financeRequest = container.read(
      teacherFinancialOverviewProvider.future,
    );
    expect(insights.financeRequests, 1);
    insights.finance.complete(
      const TeacherFinancialOverview(netEarningsMinor: 12000),
    );
    expect((await financeRequest).formatMinor(12000), 'Rs 120');
  });
}
