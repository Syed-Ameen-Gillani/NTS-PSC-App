import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/home_screen.dart';
import 'package:nts_psc_app/features/onboarding/data/learning_preferences_repository.dart';
import 'package:nts_psc_app/features/onboarding/domain/course_interest_ranking.dart';
import 'package:nts_psc_app/features/onboarding/domain/learning_preferences.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';

const _pedagogy = LearningPreferences(
  categories: ['Education'],
  interests: ['Pedagogy'],
  skills: ['Lesson Planning'],
);
final _preferences = StateProvider<LearningPreferences>((ref) => _pedagogy);

CourseModel _course(String id, String title, String category) => CourseModel(
  id: id,
  title: title,
  category: category,
  author: 'Instructor',
  rating: 0,
  price: 'Free',
  imagePath: AppAssets.course1,
);

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => AuthState();
}

class _Home extends HomeController {
  @override
  Future<HomeState> build() async => HomeState(
    preferences: await ref.watch(currentLearningPreferencesProvider.future),
    categories: [
      CategoryModel(id: 'fpsc', name: 'FPSC', courseCount: 1, iconType: 'book'),
    ],
    newCourses: [
      _course('teaching', 'Pedagogy', 'General'),
      _course('exam', 'FPSC', 'FPSC'),
    ],
  );
}

void main() {
  test(
    'survey interests and skills cover all topics and prefer an explicit interest on a tie',
    () {
      final ranking = CourseInterestRanking(_pedagogy);
      expect(ranking.initialTopic([]), 'Pedagogy');
      expect(
        ranking.matches(
          _course('one', 'Teaching foundations', 'General'),
          'Lesson Planning',
        ),
        isTrue,
      );
      final topics = ranking.topics([]);
      expect(
        topics,
        containsAll({
          ...LearningPreferences.interestOptions.keys,
          ...LearningPreferences.interestOptions.values.expand(
            (values) => values,
          ),
          ...LearningPreferences.defaultSkills,
          ...LearningPreferences.suggestedSkills(
            LearningPreferences.interestOptions.values.expand(
              (values) => values,
            ),
          ),
        }),
      );
      expect(topics.toSet().length, topics.length);
      expect(
        CourseInterestRanking(const LearningPreferences()).initialTopic([]),
        'All',
      );
    },
  );

  test('ranking matches whole terms and keeps custom skills available', () {
    final ranking = CourseInterestRanking(
      const LearningPreferences(
        categories: ['Competitive Exams'],
        interests: ['CSS'],
        skills: ['Interview Practice'],
      ),
    );
    expect(
      ranking.score('CSS preparation'),
      greaterThan(ranking.score('History')),
    );
    expect(
      ranking.matches(_course('one', 'Processing methods', 'General'), 'CSS'),
      isFalse,
    );
    expect(ranking.topics([]), contains('Interview Practice'));
    expect(ranking.terms.every((term) => (term['weight'] as int) <= 4), isTrue);
  });

  testWidgets(
    'dashboard previews fixed chips, preserves manual selection, and resets after survey changes',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          homeControllerProvider.overrideWith(_Home.new),
          currentLearningPreferencesProvider.overrideWith(
            (ref) => ref.watch(_preferences),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => const MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      CategoryFilterChips chips() =>
          tester.widget<CategoryFilterChips>(find.byType(CategoryFilterChips));
      expect(chips().wrap, isTrue);
      expect(chips().filters.length, lessThanOrEqualTo(4));
      expect(chips().filters[chips().initialSelectedIndex], 'Pedagogy');
      expect(
        find.descendant(
          of: find.byType(CategoryFilterChips),
          matching: find.byType(ListView),
        ),
        findsNothing,
      );

      final otherTopic = chips().filters.last;
      final otherChip = find.descendant(
        of: find.byType(CategoryFilterChips),
        matching: find.text(otherTopic),
      );
      await tester.ensureVisible(otherChip);
      await tester.tap(otherChip);
      await tester.pumpAndSettle();
      final selectedLabel = tester.widget<Text>(
        find.descendant(
          of: find.byType(CategoryFilterChips),
          matching: find.text(otherTopic),
        ),
      );
      expect(
        selectedLabel.style!.color,
        Theme.of(
          tester.element(find.byType(CategoryFilterChips)),
        ).colorScheme.onPrimary,
      );

      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      container.invalidate(homeControllerProvider);
      await tester.pumpAndSettle();
      expect(chips().filters[chips().initialSelectedIndex], 'All');
      container.read(_preferences.notifier).state = const LearningPreferences(
        categories: ['Education'],
        interests: ['English'],
      );
      await tester.pumpAndSettle();
      expect(chips().filters[chips().initialSelectedIndex], 'English');

      final header = find.ancestor(
        of: find.text('Course Categories'),
        matching: find.byType(Row),
      );
      final seeAll = find.descendant(
        of: header,
        matching: find.text('See All'),
      );
      await tester.ensureVisible(seeAll);
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(find.text('KPPSC'), findsOneWidget);
      expect(find.text('Assessment Design'), findsOneWidget);
    },
  );
}
