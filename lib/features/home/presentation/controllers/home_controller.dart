import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';

class HomeState {
  final List<CourseModel> featuredCourses;
  final List<CourseModel> continueLearningCourses;
  final List<CategoryModel> categories;
  final List<CourseModel> newCourses;

  HomeState({
    this.featuredCourses = const [],
    this.continueLearningCourses = const [],
    this.categories = const [],
    this.newCourses = const [],
  });
}

class HomeController extends AsyncNotifier<HomeState> {
  @override
  FutureOr<HomeState> build() async {
    if (AppConfig.isSupabaseEnabled) {
      final catalogRequest = ref.watch(publishedCatalogProvider.future);
      final categoriesRequest = ref.watch(allCategoriesProvider.future);
      final learningRequest = ref.watch(myLearningControllerProvider.future);
      final featuredRequest = ref.watch(featuredCatalogProvider.future);
      final catalog = await catalogRequest;
      final categories = await categoriesRequest;
      final learning = await learningRequest;
      final featured = await featuredRequest;
      return HomeState(
        featuredCourses: featured,
        continueLearningCourses: learning.ongoingCourses,
        categories: categories,
        newCourses: catalog,
      );
    }
    // Simulate slight loading
    await Future.delayed(const Duration(milliseconds: 500));
    final categories = await ref.read(courseRepositoryProvider).getCategories();

    return HomeState(
      featuredCourses: [
        CourseModel(
          id: '1',
          title: 'FPSC Inspector Customs...',
          author: 'Sir Tariq',
          rating: 4.8,
          price: 'Rs 2,500',
          imagePath: AppAssets.course4,
          isFeatured: true,
        ),
        CourseModel(
          id: '2',
          title: 'AJK PSC Gen...',
          author: 'Dr. Usman',
          rating: 4.8,
          price: 'Rs 2,000',
          imagePath: AppAssets.course1,
          isFeatured: true,
        ),
      ],
      continueLearningCourses: [
        CourseModel(
          id: '3',
          title: 'Everyday Science Complete',
          author: 'Dr. Usman',
          rating: 0.0,
          price: '',
          imagePath: AppAssets.course2,
          progress: 0.45,
        ),
        CourseModel(
          id: '4',
          title: 'English Grammar',
          author: 'Ms. Fatima',
          rating: 0.0,
          price: '',
          imagePath: AppAssets.course3,
          progress: 0.80,
        ),
      ],
      categories: categories
          .where(
            (category) =>
                const {'AJK PSC', 'FPSC', 'NTS', 'CSS'}.contains(category.name),
          )
          .toList(),
      newCourses: [
        CourseModel(
          id: '5',
          title: 'Current Affairs 2024',
          author: 'Prof. Ali',
          rating: 5.0,
          price: 'Rs 1,200',
          imagePath: AppAssets.course5,
        ),
        CourseModel(
          id: '6',
          title: 'Pakistan Affairs Masters',
          author: 'Sir Tariq',
          rating: 4.7,
          price: 'Rs 1,500',
          imagePath: AppAssets.course6,
        ),
      ],
    );
  }
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(
  () {
    return HomeController();
  },
);

/// Shared published catalog for student-facing previews and lists.
final publishedCatalogProvider = FutureProvider<List<CourseModel>>((ref) {
  ref.watch(authControllerProvider.select((state) => state.value?.user?.id));
  final repository = ref.read(courseRepositoryProvider);
  if (AppConfig.isSupabaseEnabled) {
    return (repository as SupabaseCourseRepository).getNewCoursesPage(
      offset: 0,
      limit: 12,
    );
  }
  return repository.getNewCourses();
});

final featuredCatalogProvider = FutureProvider<List<CourseModel>>((ref) {
  ref.watch(authControllerProvider.select((state) => state.value?.user?.id));
  final repository = ref.read(courseRepositoryProvider);
  return AppConfig.isSupabaseEnabled
      ? (repository as SupabaseCourseRepository).getFeaturedCoursesPreview()
      : repository.getFeaturedCourses();
});

final allNewCoursesProvider = FutureProvider<List<CourseModel>>((ref) {
  ref.watch(authControllerProvider.select((state) => state.value?.user?.id));
  return AppConfig.isSupabaseEnabled
      ? ref.read(courseRepositoryProvider).getNewCourses()
      : ref.watch(publishedCatalogProvider.future);
});
