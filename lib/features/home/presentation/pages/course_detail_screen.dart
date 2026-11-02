import 'package:nts_psc_app/features/home/presentation/controllers/course_reviews_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_enroll_modal.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_overview_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_instructor_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_reviews_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_detail_tabs_header.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseModel? course;
  final CourseViewMode viewMode;

  const CourseDetailScreen({
    super.key,
    this.course,
    this.viewMode = CourseViewMode.automatic,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseModel _course;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.course != null) _course = widget.course!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.course == null) {
      return const AppScaffold(body: Center(child: Text('Course not found')));
    }
    if (AppConfig.isSupabaseEnabled) {
      // Use the same server-backed access/progress snapshot as the player.
      // Keep the supplied course visible while the shared provider refreshes.
      final currentCourse = ref
          .watch(lessonAccessCourseProvider(widget.course!.id))
          .value;
      if (currentCourse != null) _course = currentCourse;
      final reviews = ref
          .watch(courseReviewsProvider((courseId: _course.id, rating: null)))
          .value;
      if (reviews != null) _course = _course.copyWith(rating: reviews.average);
    }
    final isEnrolled = AppConfig.isSupabaseEnabled
        ? _course.hasEntitlement
        : _course.progress != null;
    final authState = ref.watch(authControllerProvider).value;
    final user = authState?.user;
    final isTeacherRole = AppConfig.isSupabaseEnabled
        ? user?.role == UserRole.teacher
        : authState?.selectedRole == UserRole.teacher;
    final isOwner =
        isTeacherRole &&
        (AppConfig.isSupabaseEnabled
            ? user?.id == _course.instructorId
            : _course.instructorId.isEmpty || user?.id == _course.instructorId);
    final isLearnerPreview =
        widget.viewMode == CourseViewMode.learnerPreview && isOwner;
    final isReadOnlyPreview = isLearnerPreview || (isTeacherRole && !isOwner);
    final showInstructorControls = isOwner && !isLearnerPreview;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 230.h,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                if (showInstructorControls)
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.folder_shared_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    tooltip: 'Handouts & Notes',
                    onPressed: () {
                      CourseResourcesSheet.show(
                        context,
                        courseId: _course.id,
                        courseTitle: _course.title,
                        isTeacher: showInstructorControls,
                      );
                    },
                  ),
                if (showInstructorControls)
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    tooltip: 'Learner Analytics',
                    onPressed: () {
                      context.pushNamed(
                        AppRoute.teacherStudents.name,
                        extra: _course.title,
                      );
                    },
                  ),
                SizedBox(width: 8.w),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    DashboardCourseCover(
                      imagePath: _course.imagePath,
                      coverUrl: _course.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.h,
                      left: 24.w,
                      right: 24.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              _course.category,
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: Colors.white,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _course.title,
                            style: AppTextStyles.interBold24.copyWith(
                              color: Colors.white,
                              fontSize: 18.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: CourseDetailTabsHeader(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3.h,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey500,
                  labelStyle: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 14.sp,
                  ),
                  unselectedLabelStyle: AppTextStyles.interMedium16.copyWith(
                    fontSize: 14.sp,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Syllabus'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Instructor'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            CourseOverviewTab(
              course: _course,
              isTeacher: showInstructorControls,
              isReadOnlyPreview: isReadOnlyPreview,
            ),
            CourseCurriculumTab(
              course: _course,
              isTeacher: showInstructorControls,
              isInstructorPreview: isReadOnlyPreview,
              onLessonReturned: () {
                if (AppConfig.isSupabaseEnabled) {
                  ref.invalidate(lessonAccessCourseProvider(_course.id));
                }
              },
            ),
            CourseReviewsTab(
              courseId: _course.id,
              courseTitle: _course.title,
              isTeacher: showInstructorControls,
              isReadOnlyPreview: isReadOnlyPreview,
            ),
            CourseInstructorTab(course: _course),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.grey300, width: 1.w),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: showInstructorControls
              ? Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _course.isPublished
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _course.isPublished ? '● Published' : '○ Draft',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 11.sp,
                              color: _course.isPublished
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Instructor Studio',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomButton(
                        text: 'Manage Curriculum',
                        color: AppColors.primary,
                        onPressed: () {
                          context.pushNamed(
                            AppRoute.teacherManageCourse.name,
                            extra: _course,
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tuition Fee',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                        Text(
                          _course.price.isNotEmpty ? _course.price : 'Free',
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 18.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: isReadOnlyPreview,
                        child: CustomButton(
                          text: isEnrolled ? 'Continue Learning' : 'Enroll Now',
                          color: AppColors.primary,
                          onPressed: () async {
                            if (isEnrolled) {
                              final availableLessons = _course.modules
                                  .expand((module) => module.lessons)
                                  .where((lesson) => !lesson.isLocked)
                                  .toList();
                              final lesson =
                                  availableLessons
                                      .where((lesson) => !lesson.isCompleted)
                                      .firstOrNull ??
                                  availableLessons.firstOrNull;
                              if (lesson == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No lessons available yet.'),
                                  ),
                                );
                                return;
                              }
                              await context.pushNamed(
                                AppRoute.lessonPlayer.name,
                                extra: {
                                  'course': _course,
                                  'lesson': lesson,
                                  'mode': LessonPlayerMode.learning,
                                },
                              );
                              if (context.mounted &&
                                  AppConfig.isSupabaseEnabled) {
                                ref.invalidate(
                                  lessonAccessCourseProvider(_course.id),
                                );
                              }
                            } else {
                              final enrolled =
                                  await showModalBottomSheet<CourseModel>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        CourseEnrollModal(course: _course),
                                  );
                              if (AppConfig.isSupabaseEnabled &&
                                  enrolled != null &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Enrollment successful'),
                                    ),
                                  );
                                _course = enrolled;
                                ref.invalidate(
                                  lessonAccessCourseProvider(enrolled.id),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
