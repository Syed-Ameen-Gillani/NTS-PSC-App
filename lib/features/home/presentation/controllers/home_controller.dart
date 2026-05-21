import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

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
    // Simulate slight loading
    await Future.delayed(const Duration(milliseconds: 500));
    
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
      categories: [
        CategoryModel(id: 'c1', name: 'AJK PSC', courseCount: 12, iconType: 'document'),
        CategoryModel(id: 'c2', name: 'FPSC', courseCount: 8, iconType: 'globe'),
        CategoryModel(id: 'c3', name: 'NTS', courseCount: 15, iconType: 'clipboard'),
        CategoryModel(id: 'c4', name: 'CSS', courseCount: 5, iconType: 'book'),
      ],
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

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(() {
  return HomeController();
});
