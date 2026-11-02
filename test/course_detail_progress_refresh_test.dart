import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/domain/course_reviews.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_instructor_provider.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_reviews_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_detail_screen.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 'student',
      name: 'Student',
      email: 'fixture@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 1,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

class _Reviews extends CourseReviewsController {
  _Reviews(super.query);
  @override
  Future<CourseReviewsPage> build() async => const CourseReviewsPage(
    items: [],
    count: 0,
    average: 0,
    distribution: [0, 0, 0, 0, 0],
    canReview: false,
  );
}

void main() {
  testWidgets('syllabus consumes the player access snapshot after refresh', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = true;
    addTearDown(() => AppConfig.isSupabaseEnabled = false);
    CourseModel snapshot(bool complete) => CourseModel(
      id: 'course',
      title: 'Course',
      author: 'Teacher',
      rating: 0,
      price: 'Free',
      imagePath: '',
      instructorId: 'teacher',
      hasEntitlement: true,
      modules: [
        CourseModuleModel(
          id: 'module',
          title: 'Module',
          lessons: [
            LessonModel(
              id: 'first',
              title: 'First',
              durationMinutes: 1,
              notes: 'Reading',
              isCompleted: complete,
            ),
            LessonModel(
              id: 'second',
              title: 'Second',
              durationMinutes: 1,
              notes: complete ? 'Reading' : '',
              isLocked: !complete,
            ),
          ],
        ),
      ],
    );
    var server = snapshot(false);
    final initial = server;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        courseReviewsProvider.overrideWith(
          () => _Reviews((courseId: 'course', rating: null)),
        ),
        courseInstructorProvider.overrideWith((ref, id) async => null),
        lessonAccessCourseProvider.overrideWith((ref, id) async => server),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: CourseDetailScreen(course: initial)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Syllabus'));
    await tester.pumpAndSettle();
    CourseModel displayed() => tester
        .widget<CourseCurriculumTab>(find.byType(CourseCurriculumTab))
        .course;
    expect(displayed().modules.first.lessons.last.isLocked, isTrue);
    server = snapshot(true);
    container.invalidate(lessonAccessCourseProvider('course'));
    await tester.pumpAndSettle();
    expect(displayed().modules.first.lessons.first.isCompleted, isTrue);
    expect(displayed().modules.first.lessons.last.isLocked, isFalse);
    expect(initial.modules.first.lessons.last.isLocked, isTrue);
    expect(tester.takeException(), isNull);
  });
}
