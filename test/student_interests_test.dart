import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_choice_chip.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/onboarding/data/learning_preferences_repository.dart';
import 'package:nts_psc_app/features/onboarding/domain/learning_preferences.dart';
import 'package:nts_psc_app/features/onboarding/presentation/widgets/student_interest_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => AuthState();

  void signIn(String id, [UserRole role = UserRole.student]) {
    state = AsyncData(
      AuthState(
        isAuthenticated: true,
        user: UserModel(
          id: id,
          name: 'Student',
          email: '$id@example.invalid',
          imagePath: '',
          isPremium: false,
          courses: 0,
          quizzes: 0,
          avgScore: 0,
          role: role,
        ),
      ),
    );
  }

  @override
  Future<void> logout() async => state = AsyncData(AuthState());
}

class _Preferences extends LearningPreferencesRepository {
  _Preferences()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final rows = <String, LearningPreferences>{};
  int saves = 0;
  bool fail = false;

  @override
  Future<LearningPreferences> load(String owner) async =>
      rows[owner] ?? const LearningPreferences();

  @override
  Future<void> save(String owner, LearningPreferences preferences) async {
    saves++;
    if (fail) throw StateError('Network unavailable');
    rows[owner] = LearningPreferences(
      categories: preferences.categories,
      interests: preferences.interests,
      skills: preferences.skills,
      completed: true,
    );
  }
}

class _Courses extends SupabaseCourseRepository {
  _Courses()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  int requests = 0;

  @override
  Future<List<CourseModel>> getRecommendedCoursesPage({
    required int offset,
    int limit = 20,
  }) async {
    requests++;
    return [];
  }
}

void main() {
  late _Preferences preferences;
  late ProviderContainer container;
  setUp(() {
    preferences = _Preferences();
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        learningPreferencesRepositoryProvider.overrideWithValue(preferences),
      ],
    );
    AppConfig.isSupabaseEnabled = true;
  });
  tearDown(() {
    container.dispose();
    AppConfig.isSupabaseEnabled = false;
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (_, child) => StudentInterestGate(child: child!),
            home: const Scaffold(body: Text('Login or current screen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseEnglish(WidgetTester tester) async {
    await tester.tap(find.text('Education'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'survey appears only after login and saves skills without replacing the underlying screen',
    (tester) async {
      await mount(tester);
      expect(find.text('What would you like to learn?'), findsNothing);
      final before = tester.element(find.text('Login or current screen'));
      (container.read(authControllerProvider.notifier) as _Auth).signIn('one');
      await tester.pumpAndSettle();
      expect(find.text('What would you like to learn?'), findsOneWidget);
      expect(find.text('Competitions'), findsOneWidget);
      expect(find.text('Competitive Exams'), findsOneWidget);
      expect(find.text('Pedagogy'), findsNothing);
      await chooseEnglish(tester);
      expect(find.text('Pedagogy'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      await tester.ensureVisible(find.text('Time Management'));
      await tester.tap(find.text('Time Management'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add'));
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Public Speaking');
      await tester.ensureVisible(find.text('Add skills').last);
      await tester.tap(find.text('Add skills').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Continue'), 200);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(preferences.saves, 1);
      expect(preferences.rows['one']!.skills, contains('Public Speaking'));
      expect(preferences.rows['one']!.skills, contains('Time Management'));
      expect(find.text('What would you like to learn?'), findsNothing);
      expect(
        tester.element(find.text('Login or current screen')),
        same(before),
      );
      await container.read(authControllerProvider.notifier).logout();
      (container.read(authControllerProvider.notifier) as _Auth).signIn('one');
      await tester.pumpAndSettle();
      expect(find.text('What would you like to learn?'), findsNothing);
      (container.read(authControllerProvider.notifier) as _Auth).signIn('two');
      await tester.pumpAndSettle();
      expect(find.text('What would you like to learn?'), findsOneWidget);
      expect(find.text('Public Speaking'), findsNothing);
    },
  );

  testWidgets(
    'failed saves preserve selections and category changes remove generated skills',
    (tester) async {
      await mount(tester);
      (container.read(authControllerProvider.notifier) as _Auth).signIn('one');
      await tester.pumpAndSettle();
      await chooseEnglish(tester);
      preferences.fail = true;
      await tester.scrollUntilVisible(find.text('Continue'), 200);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save your interests. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Grammar'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Education'), -200);
      await tester.ensureVisible(find.text('Education'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Education'));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsNothing);
      expect(find.text('Grammar'), findsNothing);
      expect(preferences.rows, isEmpty);
    },
  );

  testWidgets('teacher login retains its existing screen', (tester) async {
    await mount(tester);
    (container.read(authControllerProvider.notifier) as _Auth).signIn(
      'teacher',
      UserRole.teacher,
    );
    await tester.pumpAndSettle();
    expect(find.text('Login or current screen'), findsOneWidget);
    expect(find.text('What would you like to learn?'), findsNothing);
  });

  testWidgets('Profile edits the saved survey and refreshes recommendations', (
    tester,
  ) async {
    preferences.rows['one'] = const LearningPreferences(
      categories: ['Education'],
      interests: ['English'],
      skills: ['Grammar'],
      completed: true,
    );
    final courses = _Courses();
    container.dispose();
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        learningPreferencesRepositoryProvider.overrideWithValue(preferences),
        courseRepositoryProvider.overrideWithValue(courses),
      ],
    );
    await container.read(authControllerProvider.future);
    (container.read(authControllerProvider.notifier) as _Auth).signIn('one');
    final subscription = container.listen(
      recommendedCatalogProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(recommendedCatalogProvider.future);
    expect(courses.requests, 1);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: AppRoute.learningInterests.path,
          name: AppRoute.learningInterests.name,
          builder: (_, _) => const LearningInterestsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (_, child) => StudentInterestGate(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Learning preferences'));
    await tester.tap(find.text('Learning preferences'));
    await tester.pumpAndSettle();
    final english = find.ancestor(
      of: find.text('English'),
      matching: find.byType(AppChoiceChip),
    );
    expect(tester.widget<AppChoiceChip>(english).selected, isTrue);
    await tester.tap(find.text('Pedagogy'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save preferences'), 200);
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    expect(
      preferences.rows['one']!.interests,
      containsAll(['English', 'Pedagogy']),
    );
    await container.read(recommendedCatalogProvider.future);
    expect(courses.requests, 2);

    await tester.ensureVisible(find.text('Learning preferences'));
    await tester.tap(find.text('Learning preferences'));
    await tester.pumpAndSettle();
    final pedagogy = find.ancestor(
      of: find.text('Pedagogy'),
      matching: find.byType(AppChoiceChip),
    );
    expect(tester.widget<AppChoiceChip>(pedagogy).selected, isTrue);
    expect(find.text('Continue'), findsNothing);
  });

  test(
    'survey validates selected interests against their categories and normalizes skills',
    () {
      expect(
        () => const LearningPreferences(
          categories: ['Education'],
          interests: ['CSS'],
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => const LearningPreferences().validate(),
        throwsFormatException,
      );
      expect(
        LearningPreferences.clean([' Grammar ', 'grammar', '', 'Writing']),
        ['Grammar', 'Writing'],
      );
      expect(
        const LearningPreferences(
          categories: ['Education'],
          interests: ['Pedagogy'],
        ).validate,
        returnsNormally,
      );
      final legacy = LearningPreferences.fromJson({
        'categories': ['Pedagogy', 'Education'],
        'interests': ['Teaching Methods', 'English'],
        'skills': ['Lesson Planning'],
        'completed_at': '2026-11-14T00:00:00Z',
      });
      expect(legacy.categories, ['Education']);
      expect(legacy.interests, ['English', 'Pedagogy']);
      expect(legacy.validate, returnsNormally);
    },
  );
}
