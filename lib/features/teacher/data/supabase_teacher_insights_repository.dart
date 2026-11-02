import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/domain/repositories/teacher_insights_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTeacherInsightsRepository implements TeacherInsightsRepository {
  SupabaseTeacherInsightsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TeacherDashboardOverview> getDashboardOverview() async {
    final result = await _client.rpc(
      'get_teacher_dashboard_overview',
      params: const {'p_recent_limit': 5},
    );
    return mapDashboardOverview(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<TeacherFinancialOverview> getFinancialOverview() async {
    final result = await _client.rpc(
      'get_teacher_financial_overview',
      params: const {'p_history_limit': 50},
    );
    return mapFinancialOverview(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<List<TeacherLearnerEnrollment>> getLearnerRoster({
    required int limit,
    required int offset,
    String? query,
    String? courseId,
  }) async {
    final rows =
        await _client.rpc(
              'get_teacher_learner_roster',
              params: {
                'p_limit': limit,
                'p_offset': offset,
                'p_query': query,
                'p_course_id': courseId,
              },
            )
            as List<dynamic>;
    return rows
        .map((row) => mapLearnerRow(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  static TeacherLearnerEnrollment mapLearnerRow(Map<String, dynamic> row) =>
      TeacherLearnerEnrollment(
        id: row['enrollment_id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String,
        courseId: row['course_id'] as String,
        courseTitle: row['course_title'] as String,
        enrolledAt: DateTime.parse(row['enrolled_at'] as String).toLocal(),
        status: row['enrollment_status'] as String,
      );

  static TeacherDashboardOverview mapDashboardOverview(
    Map<String, dynamic> data,
  ) {
    final rows = (data['recent_enrollments'] as List<dynamic>? ?? const []);
    return TeacherDashboardOverview(
      totalStudents: _asInt(data['total_students']),
      activeCourses: _asInt(data['active_courses']),
      recentEnrollments: rows
          .map((item) {
            final row = Map<String, dynamic>.from(item as Map);
            return RecentEnrollmentModel(
              id: row['id'] as String,
              studentName: row['student_name'] as String,
              courseTitle: row['course_title'] as String,
              enrolledAt: DateTime.parse(
                row['enrolled_at'] as String,
              ).toLocal(),
            );
          })
          .toList(growable: false),
    );
  }

  static TeacherFinancialOverview mapFinancialOverview(
    Map<String, dynamic> data,
  ) {
    final rows = (data['payouts'] as List<dynamic>? ?? const []);
    return TeacherFinancialOverview(
      currency: data['currency'] as String? ?? 'PKR',
      grossSalesMinor: _asInt(data['gross_sales_minor']),
      platformFeeMinor: _asInt(data['platform_fee_minor']),
      netEarningsMinor: _asInt(data['net_earnings_minor']),
      availableBalanceMinor: _asInt(data['available_balance_minor']),
      pendingBalanceMinor: _asInt(data['pending_balance_minor']),
      totalWithdrawnMinor: _asInt(data['total_withdrawn_minor']),
      payouts: rows
          .map((item) {
            final row = Map<String, dynamic>.from(item as Map);
            return TeacherPayoutModel(
              id: row['id'] as String,
              amountMinor: _asInt(row['amount_minor']),
              currency: row['currency'] as String? ?? 'PKR',
              method: row['method'] as String,
              accountMask: row['account_mask'] as String,
              status: row['status'] as String,
              providerReference: row['provider_reference'] as String?,
              requestedAt: DateTime.parse(
                row['requested_at'] as String,
              ).toLocal(),
              processedAt: row['processed_at'] == null
                  ? null
                  : DateTime.parse(row['processed_at'] as String).toLocal(),
            );
          })
          .toList(growable: false),
    );
  }

  static int _asInt(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse('$value') ?? 0;
}
