import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';

class _Auth extends AuthController {
  AuthState user(String id) => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: id,
      name: id,
      email: 'fixture@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
  @override
  AuthState build() => user('first-student');
  void switchAccount() => state = AsyncData(user('second-student'));
}

void main() {
  testWidgets(
    'switching accounts resets the selected lesson in the same course',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _Auth();
      final course = CourseModel(
        id: 'shared-course',
        title: 'Course',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
        modules: [
          CourseModuleModel(
            id: 'module',
            title: 'Module',
            lessons: [
              LessonModel(
                id: 'first',
                title: 'First lesson',
                durationMinutes: 2,
                notes: 'First reading',
              ),
              LessonModel(
                id: 'second',
                title: 'Second lesson',
                durationMinutes: 2,
                notes: 'Second reading',
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(() => auth)],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) =>
                MaterialApp(home: LiveLessonPlayerScreen(course: course)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Second lesson').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Second lesson').last);
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsOneWidget);
      auth.switchAccount();
      await tester.pumpAndSettle();
      expect(find.text('Second reading'), findsNothing);
      expect(find.text('First reading'), findsOneWidget);
    },
  );
}

