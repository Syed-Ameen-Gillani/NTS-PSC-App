import 'package:nts_psc_app/presentation/widgets/student_tab_header.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/learn/data/offline_progress_queue.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/horizontal_course_card.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';

class MyLearningTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final myLearningTabProvider = NotifierProvider<MyLearningTab, int>(
  MyLearningTab.new,
);

class LearningSearch extends Notifier<String> {
  @override
  String build() {
    ref.watch(authControllerProvider.select((state) => state.value?.user?.id));
    return '';
  }

  void update(String value) => state = value.trim().toLowerCase();
}

final learningSearchProvider = NotifierProvider<LearningSearch, String>(
  LearningSearch.new,
);

class MyLearningScreen extends ConsumerWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningStateAsync = ref.watch(myLearningControllerProvider);
    final studentId = ref.watch(authControllerProvider).value?.user?.id;
    final tab = ref.watch(myLearningTabProvider);
    final query = ref.watch(learningSearchProvider);

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: learningStateAsync.when(
          data: (state) {
            final available = tab == 0
                ? state.ongoingCourses
                : tab == 1
                ? state.completedCourses
                : state.downloadedCourses;
            final courses = available
                .where(
                  (course) =>
                      course.title.toLowerCase().contains(query) ||
                      course.category.toLowerCase().contains(query) ||
                      course.author.toLowerCase().contains(query),
                )
                .toList();
            return RefreshIndicator(
              onRefresh: () async {
                if (AppConfig.isSupabaseEnabled) {
                  await ref.read(offlineProgressQueueProvider).sync();
                }
                ref.invalidate(myLearningControllerProvider);
                await ref.read(myLearningControllerProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentTabHeader(
                      title: 'My Learning',
                      action: AppConfig.isSupabaseEnabled
                          ? IconButton(
                              tooltip: 'Downloads',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () => context.pushNamed(
                                AppRoute.offlineDownloads.name,
                              ),
                            )
                          : null,
                      search: CourseSearchField(
                        key: ValueKey(studentId),
                        initialValue: query,
                        hintText: 'Search your courses',
                        onChanged: ref
                            .read(learningSearchProvider.notifier)
                            .update,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CategoryFilterChips(
                      filters: AppConfig.isSupabaseEnabled
                          ? const ['Ongoing', 'Completed']
                          : const ['Ongoing', 'Completed', 'Downloaded'],
                      initialSelectedIndex: tab,
                      onSelected: ref
                          .read(myLearningTabProvider.notifier)
                          .select,
                    ),
                    SizedBox(height: 24.h),
                    if (courses.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          query.isEmpty
                              ? 'No courses in this section'
                              : 'No courses match your search',
                        ),
                      ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 24.w,
                        right: 24.w,
                        bottom: 48.h,
                      ),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HorizontalCourseCard(course: course),
                            if (course.learningComplete == true)
                              TextButton.icon(
                                onPressed: () => context.pushNamed(
                                  AppRoute.courseCertificate.name,
                                  queryParameters: {'courseId': course.id},
                                ),
                                icon: const Icon(
                                  Icons.workspace_premium_outlined,
                                ),
                                label: const Text('View certificate'),
                              ),
                            if (course.remainingAssessments > 0)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  '${course.remainingAssessments} assessments still required',
                                  style: AppTextStyles.interRegular14.copyWith(
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(myLearningControllerProvider),
              child: const Text('Could not load your courses. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}
