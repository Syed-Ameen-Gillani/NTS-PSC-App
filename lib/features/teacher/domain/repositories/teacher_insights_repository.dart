import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';

abstract class TeacherInsightsRepository {
  Future<TeacherDashboardOverview> getDashboardOverview();
  Future<TeacherFinancialOverview> getFinancialOverview();
  Future<List<TeacherLearnerEnrollment>> getLearnerRoster({
    required int limit,
    required int offset,
    String? query,
    String? courseId,
  });
}
