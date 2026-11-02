import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';

class DiscoverState {
  final List<CategoryModel> trendingCategories;
  final List<TeacherModel> popularTeachers;
  final List<CourseModel> topRatedCourses;
  final List<CourseModel> recommendedCourses;

  DiscoverState({
    this.trendingCategories = const [],
    this.popularTeachers = const [],
    this.topRatedCourses = const [],
    this.recommendedCourses = const [],
  });
}

class DiscoverController extends AsyncNotifier<DiscoverState> {
  @override
  FutureOr<DiscoverState> build() async {
    if (AppConfig.isSupabaseEnabled) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      final repository = ref.read(courseRepositoryProvider);
      final categoriesRequest = ref.watch(allCategoriesProvider.future);
      final coursesRequest = ref.watch(publishedCatalogProvider.future);
      final teachersRequest = (repository as SupabaseCourseRepository)
          .getPublicTeachers(limit: 4);
      final categories = await categoriesRequest;
      final courses = await coursesRequest;
      return DiscoverState(
        trendingCategories: categories
            .where((category) => category.courseCount > 0)
            .toList(),
        popularTeachers: await teachersRequest,
        topRatedCourses: const [],
        recommendedCourses: courses,
      );
    }
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate API call
    final repository = ref.read(courseRepositoryProvider);
    final categories = await repository.getCategories();
    final courses = await repository.getCoursesByCategory(null);
    final topRated = [...courses]..sort((a, b) => b.rating.compareTo(a.rating));
    final featured = topRated.take(2).toList();

    return DiscoverState(
      trendingCategories: [
        for (final name in const ['CSS', 'PMS', 'FPSC', 'NTS'])
          ...categories.where((category) => category.name == name),
      ],
      popularTeachers: [
        TeacherModel(
          id: 't1',
          name: 'Sir Tariq',
          subject: 'Pakistan Studies',
          imagePath: AppAssets.teacher1,
        ),
        TeacherModel(
          id: 't2',
          name: 'Dr. Usman',
          subject: 'General Science',
          imagePath: AppAssets.teacher2,
        ),
        TeacherModel(
          id: 't3',
          name: 'Ms. Fatima',
          subject: 'English',
          imagePath: AppAssets.teacher1,
        ),
      ],
      topRatedCourses: featured,
      recommendedCourses: courses
          .where((course) => !featured.any((item) => item.id == course.id))
          .toList(),
    );
  }
}

final discoverControllerProvider =
    AsyncNotifierProvider<DiscoverController, DiscoverState>(() {
      return DiscoverController();
    });

const publicTeacherPageSize = 20;

class PublicTeacherPageIndex extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state++;
}

final publicTeacherPageIndexProvider =
    NotifierProvider<PublicTeacherPageIndex, int>(PublicTeacherPageIndex.new);

final publicTeacherPageProvider = FutureProvider.autoDispose
    .family<List<TeacherModel>, int>((ref, page) {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      return (ref.read(courseRepositoryProvider) as SupabaseCourseRepository)
          .getPublicTeachers(
            limit: publicTeacherPageSize,
            offset: page * publicTeacherPageSize,
          );
    });

final publicTeacherPagesProvider = FutureProvider.autoDispose
    .family<List<List<TeacherModel>>, int>((ref, lastPage) {
      return Future.wait([
        for (var page = 0; page <= lastPage; page++)
          ref.watch(publicTeacherPageProvider(page).future),
      ]);
    });
