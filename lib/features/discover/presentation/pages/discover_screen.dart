import 'package:nts_psc_app/presentation/widgets/student_tab_header.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/browse_category_grid.dart';
import 'package:nts_psc_app/presentation/widgets/popular_teachers_list.dart';
import 'package:nts_psc_app/presentation/widgets/featured_course_list.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

class DiscoverScreen extends ConsumerWidget {
  static const _recommendedPreviewLimit = 3;
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverStateAsync = ref.watch(discoverControllerProvider);

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: discoverStateAsync.when(
          data: (state) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(publishedCatalogProvider);
                ref.invalidate(featuredCatalogProvider);
                ref.invalidate(allCategoriesProvider);
                ref.invalidate(discoverControllerProvider);
                await ref.read(discoverControllerProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StudentTabHeader(
                      title: 'Discover',
                      search: CustomSearchBar(includePadding: false),
                    ),
                    SizedBox(height: 32.h),
                    BrowseCategoryGrid(
                      title: 'Trending\nCategories',
                      actionText: 'View All',
                      categories: state.trendingCategories,
                    ),
                    SizedBox(height: 32.h),
                    PopularTeachersList(teachers: state.popularTeachers),
                    SizedBox(height: 32.h),
                    if (state.topRatedCourses.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          'Top Rated Courses',
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 18.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                    if (state.topRatedCourses.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      FeaturedCourseList(courses: state.topRatedCourses),
                      SizedBox(height: 32.h),
                    ],
                    NewCoursesList(
                      title: 'Explore More Courses',
                      courses: state.recommendedCourses
                          .take(_recommendedPreviewLimit)
                          .toList(),
                      actionText:
                          state.recommendedCourses.length >
                              _recommendedPreviewLimit
                          ? 'See all'
                          : null,
                      onActionPressed: () => context.pushNamed(
                        AppRoute.newCourses.name,
                        queryParameters: const {'section': 'recommended'},
                      ),
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(discoverControllerProvider),
              child: const Text('Could not load courses. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}
