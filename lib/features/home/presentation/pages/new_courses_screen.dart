import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/catalog_pages_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

class NewCoursesScreen extends ConsumerWidget {
  const NewCoursesScreen({super.key, this.section = 'new', this.category});

  final String section;
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (section) {
      'featured' => 'Featured Courses',
      'continue' => 'Continue Learning',
      'recommended' => 'Explore more courses',
      'available' =>
        category == null ? 'Available Courses' : '$category Courses',
      _ => 'New Courses',
    };
    final paged = AppConfig.isSupabaseEnabled && section != 'continue';
    final listKey = (section: section, category: category);
    final page = paged ? ref.watch(catalogPageIndexProvider(listKey)) : 0;
    final pages = paged
        ? ref.watch(catalogPagesProvider((list: listKey, page: page)))
        : null;
    final previousPages = paged && page > 0
        ? ref.watch(catalogPagesProvider((list: listKey, page: page - 1)))
        : null;
    final loadingMore =
        paged && pages!.isLoading && previousPages?.hasValue == true;
    final loadMoreError =
        paged && pages!.hasError && previousPages?.hasValue == true;
    final visiblePages = loadingMore || loadMoreError ? previousPages! : pages;
    final courses = paged
        ? visiblePages!.whenData(
            (parts) => parts.expand((items) => items).toList(),
          )
        : section == 'new'
        ? ref.watch(allNewCoursesProvider)
        : section == 'recommended'
        ? ref
              .watch(discoverControllerProvider)
              .whenData((state) => state.recommendedCourses)
        : ref.watch(homeControllerProvider).whenData((state) {
            if (section == 'featured') return state.featuredCourses;
            if (section == 'continue') return state.continueLearningCourses;
            final seen = <String>{};
            return [...state.featuredCourses, ...state.newCourses]
                .where(
                  (course) =>
                      seen.add(course.id) &&
                      (category == null || course.category == category),
                )
                .toList();
          });
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          title,
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: courses.when(
          data: (items) => items.isEmpty
              ? Center(
                  child: Text(
                    section == 'continue'
                        ? 'Enroll in a course to start learning here.'
                        : 'No courses available',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Column(
                    children: [
                      NewCoursesList(
                        title: paged
                            ? '${items.length} ${items.length == 1 ? 'course' : 'courses'} shown'
                            : '${items.length} ${items.length == 1 ? 'course' : 'courses'}',
                        courses: items,
                      ),
                      if (paged &&
                          (loadingMore ||
                              loadMoreError ||
                              pages!.value?.last.length == catalogPageSize))
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: loadMoreError
                                      ? () => ref.invalidate(
                                          catalogPageProvider((
                                            list: listKey,
                                            page: page,
                                          )),
                                        )
                                      : ref
                                            .read(
                                              catalogPageIndexProvider(
                                                listKey,
                                              ).notifier,
                                            )
                                            .next,
                                  child: Text(
                                    loadMoreError ? 'Retry' : 'Show more',
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () {
                if (paged) {
                  for (var index = 0; index <= page; index++) {
                    ref.invalidate(
                      catalogPageProvider((list: listKey, page: index)),
                    );
                  }
                } else if (section == 'recommended') {
                  ref.invalidate(discoverControllerProvider);
                } else if (section == 'new') {
                  ref.invalidate(allNewCoursesProvider);
                } else {
                  ref.invalidate(homeControllerProvider);
                }
              },
              child: const Text('Could not load courses. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}
