import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/domain/repositories/teacher_insights_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_learner_roster_controller.dart';

class _TeacherAuth extends AuthController {
  @override
  FutureOr<AuthState> build() => AuthState(
    user: UserModel(
      id: 'teacher-1',
      name: 'Teacher',
      email: 'teacher@example.com',
      imagePath: '',
      isPremium: false,
      courses: 1,
      quizzes: 0,
      avgScore: 0,
      role: UserRole.teacher,
    ),
    selectedRole: UserRole.teacher,
    isAuthenticated: true,
  );
}

class _Repository implements TeacherInsightsRepository {
  final calls = <({int offset, String? query, String? courseId})>[];
  final items = [
    for (var index = 0; index < 51; index++)
      TeacherLearnerEnrollment(
        id: 'enrollment-$index',
        studentId: 'student-$index',
        studentName: 'Student $index',
        courseId: 'course-1',
        courseTitle: 'Kashmir Studies',
        enrolledAt: DateTime(2026, 10, 24),
        status: 'active',
      ),
  ];

  @override
  Future<TeacherDashboardOverview> getDashboardOverview() async =>
      const TeacherDashboardOverview();

  @override
  Future<TeacherFinancialOverview> getFinancialOverview() async =>
      const TeacherFinancialOverview();

  @override
  Future<List<TeacherLearnerEnrollment>> getLearnerRoster({
    required int limit,
    required int offset,
    String? query,
    String? courseId,
  }) async {
    calls.add((offset: offset, query: query, courseId: courseId));
    final filtered = items.where(
      (item) =>
          (courseId == null || item.courseId == courseId) &&
          (query == null || item.studentName.contains(query)),
    );
    return filtered.skip(offset).take(limit).toList();
  }
}

void main() {
  test('roster pages and filters enrolled learners', () async {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_TeacherAuth.new),
        teacherInsightsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      teacherLearnerRosterProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    final first = await container.read(teacherLearnerRosterProvider.future);
    expect(first.items, hasLength(50));
    expect(first.hasMore, isTrue);

    await container.read(teacherLearnerRosterProvider.notifier).loadMore();
    final all = container.read(teacherLearnerRosterProvider).value!;
    expect(all.items, hasLength(51));
    expect(all.items.map((item) => item.id).toSet(), hasLength(51));
    expect(all.hasMore, isFalse);
    expect(repository.calls[1].offset, 50);

    await container
        .read(teacherLearnerRosterProvider.notifier)
        .setFilters(query: 'Student 50', courseId: 'course-1');
    final filtered = container.read(teacherLearnerRosterProvider).value!;
    expect(filtered.items.single.studentName, 'Student 50');
    expect(repository.calls.last.query, 'Student 50');
    expect(repository.calls.last.courseId, 'course-1');
  });
}
