import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/course_search_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

/// Searches published courses in small pages and ignores stale query responses.
class CourseSearchScreen extends ConsumerWidget {
  const CourseSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(courseSearchQueryProvider);
    final draft = ref.watch(courseSearchDraftProvider);
    final page = ref.watch(courseSearchPageIndexProvider);
    final results = ref.watch(
      courseSearchResultsProvider((query: query, page: page)),
    );
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Search courses',
          style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: context.pop,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: CourseSearchField(
                autofocus: true,
                initialValue: query,
                hintText: 'Search courses, exams...',
                onChanged: ref.read(courseSearchQueryProvider.notifier).update,
              ),
            ),
            Expanded(
              child: draft != query
                  ? const Center(child: CircularProgressIndicator())
                  : results.when(
                      data: (pages) {
                        final matches = pages.expand((items) => items).toList();
                        if (matches.isEmpty) {
                          return Center(
                            child: Text(
                              query.isEmpty
                                  ? 'No courses available yet.'
                                  : 'No courses match your search.',
                              style: AppTextStyles.interRegular14.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          );
                        }
                        return ListView(
                          children: [
                            NewCoursesList(
                              title:
                                  '${matches.length} ${matches.length == 1 ? 'course' : 'courses'} shown',
                              courses: matches,
                            ),
                            if (pages.last.length == courseSearchPageSize)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: TextButton(
                                    onPressed: ref
                                        .read(
                                          courseSearchPageIndexProvider
                                              .notifier,
                                        )
                                        .next,
                                    child: const Text('Show more'),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                        child: TextButton(
                          onPressed: () {
                            for (var index = 0; index <= page; index++) {
                              ref.invalidate(
                                courseSearchPageProvider((
                                  query: query,
                                  page: index,
                                )),
                              );
                            }
                          },
                          child: const Text('Could not load courses. Retry'),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
