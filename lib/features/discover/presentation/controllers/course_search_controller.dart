import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';

const courseSearchPageSize = 20;

class CourseSearchQuery extends Notifier<String> {
  Timer? _delay;

  @override
  String build() {
    ref.onDispose(() => _delay?.cancel());
    return '';
  }

  void update(String value) {
    _delay?.cancel();
    final next = value.trim().toLowerCase();
    ref.read(courseSearchDraftProvider.notifier).update(next);
    if (next == state) return;
    _delay = Timer(const Duration(milliseconds: 300), () {
      ref.read(courseSearchPageIndexProvider.notifier).reset();
      state = next;
    });
  }
}

final courseSearchQueryProvider = NotifierProvider<CourseSearchQuery, String>(
  CourseSearchQuery.new,
);

class CourseSearchDraft extends Notifier<String> {
  @override
  String build() => ref.read(courseSearchQueryProvider);

  void update(String value) => state = value;
}

final courseSearchDraftProvider = NotifierProvider<CourseSearchDraft, String>(
  CourseSearchDraft.new,
);

class CourseSearchPageIndex extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state++;
  void reset() => state = 0;
}

final courseSearchPageIndexProvider =
    NotifierProvider<CourseSearchPageIndex, int>(CourseSearchPageIndex.new);

bool matchesCourseQuery(CourseModel course, String query) {
  if (query.isEmpty) return true;
  final haystack = [
    course.title,
    course.description,
    course.category,
    course.author,
  ].join(' ').toLowerCase();
  return query.toLowerCase().split(RegExp(r'\s+')).every(haystack.contains);
}

final courseSearchPageProvider = FutureProvider.autoDispose
    .family<List<CourseModel>, ({String query, int page})>((
      ref,
      request,
    ) async {
      ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      if (AppConfig.isSupabaseEnabled) {
        return (ref.read(courseRepositoryProvider) as SupabaseCourseRepository)
            .searchPublishedCourses(
              request.query,
              offset: request.page * courseSearchPageSize,
              limit: courseSearchPageSize,
            );
      }
      final catalog = await ref.watch(publishedCatalogProvider.future);
      return catalog
          .where((course) => matchesCourseQuery(course, request.query))
          .skip(request.page * courseSearchPageSize)
          .take(courseSearchPageSize)
          .toList();
    });

final courseSearchResultsProvider = FutureProvider.autoDispose
    .family<List<List<CourseModel>>, ({String query, int page})>((
      ref,
      request,
    ) {
      final pages = [
        for (var index = 0; index <= request.page; index++)
          ref.watch(
            courseSearchPageProvider((
              query: request.query,
              page: index,
            )).future,
          ),
      ];
      return Future.wait(pages);
    });
