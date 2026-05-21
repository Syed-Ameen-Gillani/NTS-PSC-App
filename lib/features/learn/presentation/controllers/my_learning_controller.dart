import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class MyLearningState {
  final List<CourseModel> ongoingCourses;
  final List<CourseModel> completedCourses;
  final List<CourseModel> downloadedCourses;

  MyLearningState({
    this.ongoingCourses = const [],
    this.completedCourses = const [],
    this.downloadedCourses = const [],
  });
}

class MyLearningController extends AsyncNotifier<MyLearningState> {
  @override
  FutureOr<MyLearningState> build() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    return MyLearningState(
      ongoingCourses: [
        CourseModel(
          id: '1',
          title: 'Everyday Science',
          author: 'Dr. Usman',
          progress: 0.45,
          imagePath: AppAssets.course2,
          rating: 4.5,
          price: 'Free',
        ),
        CourseModel(
          id: '2',
          title: 'English Grammar Basics',
          author: 'Ms. Fatima',
          progress: 0.80,
          imagePath: AppAssets.course4,
          rating: 4.8,
          price: 'Rs 1,000',
        ),
        CourseModel(
          id: '3',
          title: 'Pakistan Affairs Masters',
          author: 'Sir Tariq',
          progress: 0.12,
          imagePath: AppAssets.course1,
          rating: 4.9,
          price: 'Rs 3,000',
        ),
        CourseModel(
          id: '4',
          title: 'Current Affairs 2024',
          author: 'Prof. Ali',
          progress: 0.05,
          imagePath: AppAssets.course3,
          rating: 4.7,
          price: 'Free',
        ),
      ],
      completedCourses: [],
      downloadedCourses: [],
    );
  }
}

final myLearningControllerProvider = AsyncNotifierProvider<MyLearningController, MyLearningState>(() {
  return MyLearningController();
});
