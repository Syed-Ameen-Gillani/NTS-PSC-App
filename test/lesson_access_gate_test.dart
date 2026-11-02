import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_access_gate.dart';

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
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

void main() {
  for (final preview in [false, true]) {
    testWidgets(
      preview
          ? 'student cannot forge instructor preview'
          : 'locked deep link hides protected lesson content',
      (tester) async {
        final course = CourseModel(
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
                  id: 'lesson',
                  title: 'Lesson',
                  notes: 'Protected reading',
                  durationMinutes: 5,
                  isLocked: !preview,
                  accessState: 'prerequisite_required',
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authControllerProvider.overrideWith(_Auth.new),
              lessonAccessCourseProvider.overrideWith(
                (ref, id) async => course,
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp(
                home: LessonAccessGate(
                  courseId: 'course',
                  lessonId: 'lesson',
                  mode: preview
                      ? LessonPlayerMode.instructorPreview
                      : LessonPlayerMode.learning,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Protected reading'), findsNothing);
        expect(
          find.text(
            preview
                ? 'Instructor preview is unavailable.'
                : 'Finish the earlier lessons and assessments first.',
          ),
          findsOneWidget,
        );
      },
    );
  }
}
