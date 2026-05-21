import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/horizontal_course_card.dart';

class MyLearningScreen extends ConsumerWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningStateAsync = ref.watch(myLearningControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: learningStateAsync.when(
          data: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    'My Learning',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                const CustomSearchBar(),
                SizedBox(height: 24.h),
                const CategoryFilterChips(
                  filters: ['Ongoing', 'Completed', 'Downloaded'],
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 48.h),
                    itemCount: state.ongoingCourses.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return HorizontalCourseCard(course: state.ongoingCourses[index]);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Error loading data')),
        ),
      ),
    );
  }
}
