import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/home_header.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/featured_course_list.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/continue_learning_list.dart';
import 'package:nts_psc_app/presentation/widgets/browse_category_grid.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: homeStateAsync.when(
          data: (state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  const HomeHeader(),
                  SizedBox(height: 20.h),
                  const CustomSearchBar(),
                  SizedBox(height: 20.h),
                  // Live Masterclasses Banner
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: InkWell(
                      onTap: () => context.pushNamed(AppRoute.studentLiveClasses.name),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.25),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.live_tv_rounded, color: Colors.white, size: 24.w),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          'LIVE',
                                          style: AppTextStyles.interBold24.copyWith(
                                            fontSize: 9.sp,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Text(
                                          'Interactive Masterclasses',
                                          style: AppTextStyles.interSemiBold16.copyWith(
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    'Join live sessions with top PSC & NTS mentors',
                                    style: AppTextStyles.interRegular14.copyWith(
                                      fontSize: 11.sp,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14.w),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  FeaturedCourseList(courses: state.featuredCourses),
                  SizedBox(height: 32.h),
                  const CategoryFilterChips(),
                  SizedBox(height: 32.h),
                  ContinueLearningList(courses: state.continueLearningCourses),
                  SizedBox(height: 32.h),
                  BrowseCategoryGrid(
                    title: 'Browse by\nCategory',
                    actionText: 'See All',
                    categories: state.categories,
                  ),
                  SizedBox(height: 32.h),
                  NewCoursesList(
                    title: 'New Courses',
                    courses: state.newCourses,
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading home data')),
        ),
      ),
    );
  }
}
