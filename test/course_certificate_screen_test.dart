import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/course_certificate_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/certificate_open_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/course_certificate_screen.dart';

final certificate = CourseCertificate(
  url: Uri.parse('https://example.invalid/certificate.pdf'),
  name: 'Ameen Gillani',
  course: 'NTS Preparation and General Knowledge',
  id: '61ff6de7-cf8e-4355-830d-50acff210c9e',
  completedAt: DateTime.utc(2026, 10, 26),
);

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 'student',
      name: 'Ameen',
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

class _Repository extends Fake implements CourseCertificateRepository {
  final pending = Completer<CourseCertificate>();
  int calls = 0;
  @override
  Future<CourseCertificate> prepare(String courseId) {
    calls++;
    return pending.future;
  }
}

void main() {
  testWidgets(
    'certificate fits a narrow screen with large text and stays visible during opening',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            courseCertificateProvider(
              'course',
            ).overrideWith((ref) async => certificate),
            courseCertificateRepositoryProvider.overrideWithValue(repository),
            certificateLauncherProvider.overrideWithValue((url) async => false),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              theme: ThemeData.dark(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!,
              ),
              home: const CourseCertificateScreen(courseId: 'course'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CERTIFICATE OF COMPLETION'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Open certificate PDF'), 180);
      await tester.tap(find.text('Open certificate PDF'));
      await tester.pump();
      expect(find.text('Opening certificate…'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Certificate'), findsOneWidget);
      expect(repository.calls, 1);
      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(button.onPressed, isNull);
      repository.pending.complete(certificate);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Open certificate PDF'), findsOneWidget);
      expect(
        find.text('Could not open certificate. Try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
