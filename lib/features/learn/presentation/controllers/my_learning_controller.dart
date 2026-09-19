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

  MyLearningState copyWith({
    List<CourseModel>? ongoingCourses,
    List<CourseModel>? completedCourses,
    List<CourseModel>? downloadedCourses,
  }) {
    return MyLearningState(
      ongoingCourses: ongoingCourses ?? this.ongoingCourses,
      completedCourses: completedCourses ?? this.completedCourses,
      downloadedCourses: downloadedCourses ?? this.downloadedCourses,
    );
  }
}

class MyLearningController extends AsyncNotifier<MyLearningState> {
  @override
  FutureOr<MyLearningState> build() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return MyLearningState(
      ongoingCourses: [
        CourseModel(
          id: 'c1',
          title: 'FPSC Inspector Customs & Intelligence Officer',
          author: 'Sir Tariq Mahmood',
          progress: 0.35,
          imagePath: AppAssets.course4,
          rating: 4.9,
          price: 'Rs 2,500',
        ),
        CourseModel(
          id: '1',
          title: 'Everyday Science Complete Masterclass',
          author: 'Dr. Usman',
          progress: 0.65,
          imagePath: AppAssets.course2,
          rating: 4.5,
          price: 'Free',
        ),
        CourseModel(
          id: '2',
          title: 'English Grammar & Vocabulary Basics',
          author: 'Ms. Fatima',
          progress: 0.80,
          imagePath: AppAssets.course4,
          rating: 4.8,
          price: 'Rs 1,000',
        ),
      ],
      completedCourses: [
        CourseModel(
          id: 'c3',
          title: 'Pakistan Affairs Past Papers (2015-2025)',
          author: 'Sir Tariq Mahmood',
          progress: 1.0,
          imagePath: AppAssets.course1,
          rating: 4.9,
          price: 'Rs 1,500',
        ),
      ],
      downloadedCourses: [],
    );
  }

  Future<void> enrollCourse(CourseModel course) async {
    final current = state.value;
    if (current == null) return;

    if (current.ongoingCourses.any((c) => c.id == course.id) ||
        current.completedCourses.any((c) => c.id == course.id)) {
      return;
    }

    final enrolled = course.copyWith(progress: 0.05);
    final updatedOngoing = [enrolled, ...current.ongoingCourses];
    state = AsyncValue.data(current.copyWith(ongoingCourses: updatedOngoing));
  }

  Future<void> markLessonCompleted(String courseId, String lessonId) async {
    final current = state.value;
    if (current == null) return;

    final updatedOngoing = current.ongoingCourses.map((c) {
      if (c.id == courseId) {
        final newProgress = ((c.progress ?? 0.0) + 0.2).clamp(0.0, 1.0);
        return c.copyWith(progress: newProgress);
      }
      return c;
    }).toList();

    state = AsyncValue.data(current.copyWith(ongoingCourses: updatedOngoing));
  }
}

final myLearningControllerProvider = AsyncNotifierProvider<MyLearningController, MyLearningState>(() {
  return MyLearningController();
});
