import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/browse_category_grid.dart';
import 'package:nts_psc_app/presentation/widgets/popular_teachers_list.dart';
import 'package:nts_psc_app/presentation/widgets/featured_course_list.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverStateAsync = ref.watch(discoverControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: discoverStateAsync.when(
          data: (state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      'Discover',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 24.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  const CustomSearchBar(),
                  SizedBox(height: 32.h),
                  BrowseCategoryGrid(
                    title: 'Trending\nCategories',
                    actionText: 'View All',
                    categories: state.trendingCategories,
                  ),
                  SizedBox(height: 32.h),
                  PopularTeachersList(teachers: state.popularTeachers),
                  SizedBox(height: 32.h),
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
                  SizedBox(height: 16.h),
                  FeaturedCourseList(courses: state.topRatedCourses),
                  SizedBox(height: 32.h),
                  NewCoursesList(
                    title: 'Recommended For You',
                    courses: state.recommendedCourses,
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Error loading discover data')),
        ),
      ),
    );
  }
}
