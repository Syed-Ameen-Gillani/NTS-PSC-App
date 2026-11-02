import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/data/course_reviews_repository.dart';
import 'package:nts_psc_app/features/home/domain/course_reviews.dart';

final courseReviewsProvider = AsyncNotifierProvider.autoDispose
    .family<CourseReviewsController, CourseReviewsPage, CourseReviewsKey>(
      CourseReviewsController.new,
    );

class CourseReviewsController extends AsyncNotifier<CourseReviewsPage> {
  CourseReviewsController(this.query);
  final CourseReviewsKey query;
  @override
  Future<CourseReviewsPage> build() {
    ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
    return ref.read(courseReviewsRepositoryProvider).page(query);
  }

  Future<void> more() async {
    final before = state.value;
    if (before == null || !before.hasMore || before.loadingMore) return;
    state = AsyncData(before.withItems(before.items, loading: true));
    try {
      final next = await ref
          .read(courseReviewsRepositoryProvider)
          .page(query, offset: before.items.length);
      if (!ref.mounted) return;
      final ids = before.items.map((e) => e['id']).toSet();
      state = AsyncData(
        before.withItems([
          ...before.items,
          ...next.items.where((e) => !ids.contains(e['id'])),
        ], more: next.hasMore),
      );
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          before.withItems(
            before.items,
            error: 'Could not load more reviews. Try again.',
          ),
        );
      }
    }
  }
}
