import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/onboarding/domain/course_interest_ranking.dart';
import 'package:nts_psc_app/features/onboarding/data/learning_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
  (ref) => ref.read(courseRepositoryProvider).getCategories(),
);

final categoryCoursesProvider = FutureProvider.autoDispose
    .family<List<CourseModel>, String?>((ref, category) {
      ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      return ref.read(courseRepositoryProvider).getCoursesByCategory(category);
    });

final prioritizedCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final preferences = await ref.watch(
    currentLearningPreferencesProvider.future,
  );
  final ranking = CourseInterestRanking(preferences);
  if (AppConfig.isSupabaseEnabled) {
    return (ref.read(courseRepositoryProvider) as SupabaseCourseRepository)
        .getPersonalizedCategories(ranking);
  }
  final categories = await ref.watch(allCategoriesProvider.future);
  final indexed = categories.asMap().entries.toList()
    ..sort((a, b) {
      final relevance = ranking
          .score(b.value.name)
          .compareTo(ranking.score(a.value.name));
      return relevance == 0 ? a.key.compareTo(b.key) : relevance;
    });
  return indexed.map((entry) => entry.value).toList();
});
