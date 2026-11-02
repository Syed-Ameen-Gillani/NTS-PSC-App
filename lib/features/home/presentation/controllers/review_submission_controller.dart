import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/data/course_reviews_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'course_reviews_controller.dart';
import 'home_controller.dart';

final reviewSubmissionProvider = NotifierProvider.autoDispose
    .family<ReviewSubmissionController, bool, String>(
      ReviewSubmissionController.new,
    );

class ReviewSubmissionController extends Notifier<bool> {
  ReviewSubmissionController(this.courseId);
  final String courseId;
  @override
  bool build() => false;
  Future<void> save(int rating, String body) async {
    if (state) return;
    final owner = ref.read(authControllerProvider).value?.user?.id;
    state = true;
    try {
      await ref
          .read(courseReviewsRepositoryProvider)
          .save(courseId, rating, body);
      if (!ref.mounted ||
          ref.read(authControllerProvider).value?.user?.id != owner) {
        throw StateError('Account changed.');
      }
      ref.invalidate(courseReviewsProvider);
      ref.invalidate(publishedCatalogProvider);
      ref.invalidate(featuredCatalogProvider);
      ref.invalidate(homeControllerProvider);
      ref.invalidate(myLearningControllerProvider);
      ref.invalidate(lessonAccessCourseProvider(courseId));
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
