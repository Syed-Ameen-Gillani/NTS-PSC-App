import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/teacher/data/supabase_teacher_insights_repository.dart';

void main() {
  test('maps dashboard aggregates and recent enrollments', () {
    final result = SupabaseTeacherInsightsRepository.mapDashboardOverview({
      'total_students': 8,
      'active_courses': 3,
      'recent_enrollments': [
        {
          'id': 'enrollment-1',
          'student_name': 'Ayesha',
          'course_title': 'FPSC Preparation',
          'enrolled_at': '2026-10-13T08:30:00Z',
        },
      ],
    });

    expect(result.totalStudents, 8);
    expect(result.activeCourses, 3);
    expect(result.recentEnrollments.single.studentName, 'Ayesha');
    expect(result.recentEnrollments.single.courseTitle, 'FPSC Preparation');
  });

  test('maps real financial amounts and payout history', () {
    final result = SupabaseTeacherInsightsRepository.mapFinancialOverview({
      'currency': 'PKR',
      'gross_sales_minor': 1250000,
      'platform_fee_minor': 250000,
      'net_earnings_minor': 1000000,
      'available_balance_minor': 600000,
      'pending_balance_minor': 400000,
      'total_withdrawn_minor': 250000,
      'payouts': [
        {
          'id': 'payout-1',
          'amount_minor': 250000,
          'currency': 'PKR',
          'method': 'easypaisa',
          'account_mask': '03** *** 1234',
          'status': 'completed',
          'provider_reference': 'provider-1',
          'requested_at': '2026-10-12T08:30:00Z',
          'processed_at': '2026-10-12T09:30:00Z',
        },
      ],
    });

    expect(result.formatMinor(result.availableBalanceMinor), 'Rs 6,000');
    expect(result.pendingBalanceMinor, 400000);
    expect(result.payouts.single.method, 'easypaisa');
    expect(result.payouts.single.status, 'completed');
  });

  test('maps a teacher-scoped learner enrollment without private email', () {
    final learner = SupabaseTeacherInsightsRepository.mapLearnerRow({
      'enrollment_id': 'enrollment-1',
      'student_id': 'student-1',
      'student_name': 'Ayesha',
      'course_id': 'course-1',
      'course_title': 'Kashmir Studies',
      'enrolled_at': '2026-10-24T08:30:00Z',
      'enrollment_status': 'active',
    });

    expect(learner.studentName, 'Ayesha');
    expect(learner.courseTitle, 'Kashmir Studies');
    expect(learner.status, 'active');
  });

  test('missing backend values map to truthful zero and empty states', () {
    final dashboard = SupabaseTeacherInsightsRepository.mapDashboardOverview(
      {},
    );
    final finance = SupabaseTeacherInsightsRepository.mapFinancialOverview({});

    expect(dashboard.totalStudents, 0);
    expect(dashboard.recentEnrollments, isEmpty);
    expect(finance.availableBalanceMinor, 0);
    expect(finance.payouts, isEmpty);
  });
}
