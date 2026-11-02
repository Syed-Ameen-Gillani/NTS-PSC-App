import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/home_header.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/home_notification_permission_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/featured_course_list.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/continue_learning_list.dart';
import 'package:nts_psc_app/presentation/widgets/browse_category_grid.dart';
import 'package:nts_psc_app/presentation/widgets/new_courses_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _courseFilters = ['All', 'AJK PSC', 'FPSC', 'NTS', 'CSS'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(homeNotificationPermissionPromptProvider)
            .requestOnHomeArrival();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final homeStateAsync = ref.watch(homeControllerProvider);
    final selectedFilterIndex = ref.watch(homeFilterProvider);
    final sessions = AppConfig.isSupabaseEnabled
        ? null
        : ref.watch(teacherControllerProvider).value?.liveSessions;
    final hasSessions = sessions?.isNotEmpty ?? false;
    final isLive = sessions?.any((session) => session.isLive) ?? false;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: homeStateAsync.when(
          data: (state) {
            return RefreshIndicator(
              onRefresh: () async {
                if (AppConfig.isSupabaseEnabled) {
                  ref.invalidate(myLearningControllerProvider);
                }
                ref.invalidate(publishedCatalogProvider);
                ref.invalidate(featuredCatalogProvider);
                ref.invalidate(allCategoriesProvider);
                ref.invalidate(homeControllerProvider);
                await ref.read(homeControllerProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    const HomeHeader(),
                    SizedBox(height: 20.h),
                    const CustomSearchBar(),
                    SizedBox(height: 20.h),
                    ...[
                      // Live Masterclasses Banner
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: InkWell(
                          onTap: () => context.pushNamed(
                            hasSessions
                                ? AppRoute.studentLiveClasses.name
                                : AppRoute.newCourses.name,
                            queryParameters: hasSessions
                                ? {}
                                : {'section': 'available'},
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(
                                    colors.primary,
                                    colors.secondary,
                                    0.2,
                                  )!,
                                  colors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.25),
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
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    hasSessions
                                        ? Icons.live_tv_rounded
                                        : Icons.school_outlined,
                                    color: colors.onPrimary,
                                    size: 24.w,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (hasSessions)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isLive
                                                    ? Colors.redAccent
                                                    : colors.onPrimary
                                                          .withValues(
                                                            alpha: 0.24,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                isLive ? 'LIVE' : 'UPCOMING',
                                                style: AppTextStyles.interBold24
                                                    .copyWith(
                                                      fontSize: 9.sp,
                                                      color: colors.onPrimary,
                                                      letterSpacing: 0.5,
                                                    ),
                                              ),
                                            ),
                                          if (hasSessions) SizedBox(width: 6.w),
                                          Expanded(
                                            child: Text(
                                              hasSessions
                                                  ? 'Interactive Masterclasses'
                                                  : 'Explore Courses',
                                              style: AppTextStyles
                                                  .interSemiBold16
                                                  .copyWith(
                                                    fontSize: 14.sp,
                                                    color: colors.onPrimary,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        hasSessions
                                            ? 'Join live sessions with top PSC & NTS mentors'
                                            : 'Find your next step in NTS & PSC preparation',
                                        style: AppTextStyles.interRegular14
                                            .copyWith(
                                              fontSize: 11.sp,
                                              color: colors.onPrimary
                                                  .withValues(alpha: 0.85),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 14.w,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                    ],
                    if (state.featuredCourses.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Featured Courses',
                                style: AppTextStyles.interBold24.copyWith(
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.pushNamed(
                                AppRoute.newCourses.name,
                                queryParameters: {'section': 'featured'},
                              ),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                      FeaturedCourseList(
                        courses: state.featuredCourses.take(3).toList(),
                      ),
                      SizedBox(height: 32.h),
                    ],
                    CategoryFilterChips(
                      filters: _courseFilters,
                      initialSelectedIndex: selectedFilterIndex,
                      onSelected: ref.read(homeFilterProvider.notifier).select,
                    ),
                    SizedBox(height: 20.h),
                    _CategoryCourseResults(
                      filter: _courseFilters[selectedFilterIndex],
                      courses: [...state.featuredCourses, ...state.newCourses],
                    ),
                    SizedBox(height: 32.h),
                    if (state.continueLearningCourses.isEmpty)
                      _DashboardEmptySection(
                        title: 'Continue Learning',
                        message: 'Enroll in a course to start learning here.',
                        icon: Icons.menu_book_outlined,
                        onSeeAll: () => context.pushNamed(
                          AppRoute.newCourses.name,
                          queryParameters: {'section': 'continue'},
                        ),
                      )
                    else
                      ContinueLearningList(
                        courses: state.continueLearningCourses.take(3).toList(),
                        onSeeAll: () => context.pushNamed(
                          AppRoute.newCourses.name,
                          queryParameters: {'section': 'continue'},
                        ),
                      ),
                    SizedBox(height: 32.h),
                    if (state.categories.isEmpty)
                      _DashboardEmptySection(
                        title: 'Browse by Category',
                        message: 'No categories are available yet.',
                        icon: Icons.category_outlined,
                        onSeeAll: () =>
                            context.pushNamed(AppRoute.categoryCourses.name),
                      )
                    else
                      BrowseCategoryGrid(
                        title: 'Browse by\nCategory',
                        actionText: 'See All',
                        categories: state.categories.take(4).toList(),
                      ),
                    SizedBox(height: 32.h),
                    if (state.newCourses.isEmpty)
                      _DashboardEmptySection(
                        title: 'New Courses',
                        message: 'New courses will appear here when published.',
                        icon: Icons.school_outlined,
                        onSeeAll: () =>
                            context.pushNamed(AppRoute.newCourses.name),
                      )
                    else
                      NewCoursesList(
                        title: 'New Courses',
                        actionText: 'See All',
                        onActionPressed: () =>
                            context.pushNamed(AppRoute.newCourses.name),
                        courses: state.newCourses.take(3).toList(),
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
              onPressed: () => ref.invalidate(homeControllerProvider),
              child: const Text('Could not load your home. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeFilter extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final homeFilterProvider = NotifierProvider<HomeFilter, int>(HomeFilter.new);

class _DashboardEmptySection extends StatelessWidget {
  const _DashboardEmptySection({
    required this.title,
    required this.message,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.grey300, width: 1.w),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.grey500, size: 24.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCourseResults extends StatelessWidget {
  const _CategoryCourseResults({required this.filter, required this.courses});

  final String filter;
  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final matching = courses
        .where(
          (course) =>
              seen.add(course.id) &&
              (filter == 'All' || course.category == filter),
        )
        .toList();
    if (matching.isNotEmpty) {
      return NewCoursesList(
        title: filter == 'All' ? 'Available Courses' : '$filter Courses',
        courses: matching.take(3).toList(),
        actionText: 'See All',
        onActionPressed: () => context.pushNamed(
          AppRoute.newCourses.name,
          queryParameters: {
            'section': 'available',
            if (filter != 'All') 'category': filter,
          },
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Column(
          children: [
            Icon(Icons.school_outlined, color: AppColors.grey500, size: 28.w),
            SizedBox(height: 10.h),
            Text(
              'No courses available',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 14.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              filter == 'All'
                  ? 'New courses will appear here when they are published.'
                  : 'There are no published $filter courses yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
