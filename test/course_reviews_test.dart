import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, AuthClientOptions;
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/home/data/course_reviews_repository.dart';
import 'package:nts_psc_app/features/home/domain/course_reviews.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_reviews_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/live_course_reviews.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/live_review_editor.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 'review-student',
      name: 'Student',
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
  void signOut() => state = AsyncData(AuthState());
}

class _Reviews extends CourseReviewsRepository {
  _Reviews()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  bool empty = true;
  bool fail = false;
  String? saved;
  @override
  Future<CourseReviewsPage> page(
    CourseReviewsKey key, {
    int offset = 0,
  }) async => CourseReviewsPage(
    items: empty
        ? []
        : [
            for (var i = offset; i < offset + 20; i++)
              {
                'id': '$i',
                'student_name': 'Learner $i',
                'rating': 4,
                'body': 'A useful course',
                'created_at': '2026-10-27T00:00:00Z',
              },
          ],
    count: empty ? 0 : 40,
    average: empty ? 0 : 4,
    distribution: [0, 0, 0, empty ? 0 : 40, 0],
    canReview: true,
    hasMore: !empty && offset == 0,
  );
  @override
  Future<void> save(String course, int rating, String body) async {
    if (fail) throw StateError('offline');
    saved = '$rating:$body';
  }
}

void main() {
  testWidgets('review draft is hidden after the account signs out', (
    tester,
  ) async {
    final auth = _Auth();
    final repository = _Reviews();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          courseReviewsRepositoryProvider.overrideWithValue(repository),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => const MaterialApp(
            home: Scaffold(body: LiveReviewEditor(courseId: 'course')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Private unfinished review',
    );
    auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Private unfinished review'), findsNothing);
    expect(find.text('Reopen reviews after signing in.'), findsOneWidget);
    expect(find.text('Save review'), findsNothing);
    expect(repository.saved, isNull);
  });
  test('review pagination appends real pages without duplicate IDs', () async {
    final repository = _Reviews()..empty = false;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        courseReviewsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final provider = courseReviewsProvider((courseId: 'course', rating: null));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    await container.read(provider.notifier).more();
    expect(container.read(provider).value?.items.length, 40);
    expect(container.read(provider).value?.hasMore, false);
  });
  testWidgets(
    'real review empty state is centered and offers eligible submission',
    (tester) async {
      final repository = _Reviews();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            courseReviewsRepositoryProvider.overrideWithValue(repository),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => const MaterialApp(
              home: Scaffold(body: LiveCourseReviews(courseId: 'course')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No reviews yet'), findsOneWidget);
      expect(
        tester.getCenter(find.text('No reviews yet')).dy,
        greaterThan(200),
      );
      expect(find.text('Write a review'), findsOneWidget);
    },
  );
  testWidgets('review failure retains text and rating for retry', (
    tester,
  ) async {
    final repository = _Reviews()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          courseReviewsRepositoryProvider.overrideWithValue(repository),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => const MaterialApp(
            home: Scaffold(body: LiveReviewEditor(courseId: 'course')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4 stars'));
    await tester.enterText(
      find.byType(TextFormField),
      'My review stays after a failure.',
    );
    await tester.ensureVisible(find.text('Save review'));
    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();
    expect(find.text('My review stays after a failure.'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(repository.saved, isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
