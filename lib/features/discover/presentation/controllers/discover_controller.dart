import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

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
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    return DiscoverState(
      trendingCategories: [
        CategoryModel(id: 'tc1', name: 'CSS Preparation', courseCount: 24, iconType: 'book'),
        CategoryModel(id: 'tc2', name: 'PMS Exams', courseCount: 18, iconType: 'document'),
        CategoryModel(id: 'tc3', name: 'FPSC Jobs', courseCount: 32, iconType: 'clipboard'),
        CategoryModel(id: 'tc4', name: 'NTS Tests', courseCount: 15, iconType: 'document'),
      ],
      popularTeachers: [
        TeacherModel(id: 't1', name: 'Sir Tariq', subject: 'Pakistan Studies', imagePath: AppAssets.teacher1),
        TeacherModel(id: 't2', name: 'Dr. Usman', subject: 'General Science', imagePath: AppAssets.teacher2),
        TeacherModel(id: 't3', name: 'Ms. Fatima', subject: 'English', imagePath: AppAssets.teacher1),
      ],
      topRatedCourses: [
        CourseModel(
          id: 'c1',
          title: 'CSS English Essay Writing',
          author: 'Ms. Fatima',
          rating: 5.0,
          price: 'Rs 3,000',
          imagePath: AppAssets.course4,
        ),
        CourseModel(
          id: 'c2',
          title: 'PMS General Science',
          author: 'Dr. Usman',
          rating: 4.9,
          price: 'Rs 2,500',
          imagePath: AppAssets.course1,
        ),
      ],
      recommendedCourses: [
        CourseModel(
          id: 'c3',
          title: 'Everyday Science',
          author: 'Dr. Usman',
          rating: 4.7,
          price: 'Rs 1,800',
          imagePath: AppAssets.course2,
        ),
        CourseModel(
          id: 'c4',
          title: 'Islamic Studies MCQs',
          author: 'Dr. Aisha',
          rating: 4.9,
          price: 'Rs 900',
          imagePath: AppAssets.course3,
        ),
      ],
    );
  }
}

final discoverControllerProvider = AsyncNotifierProvider<DiscoverController, DiscoverState>(() {
  return DiscoverController();
});
