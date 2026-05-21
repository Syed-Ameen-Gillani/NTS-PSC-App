import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                  SizedBox(height: 20.h), // Tightened slightly to associate search with header
                  const CustomSearchBar(),
                  SizedBox(height: 32.h), // Standardized 32.h rhythm for major sections
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
                  SizedBox(height: 48.h), // Extra padding at the bottom for smooth scroll clearance above bottom nav
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
