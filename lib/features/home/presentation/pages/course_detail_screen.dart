import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_enroll_modal.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_overview_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_certificate_dialog.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_instructor_tab.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_reviews_tab.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseModel? course;

  const CourseDetailScreen({super.key, this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseModel _course;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _course = widget.course ??
        CourseModel(
          id: 'c1',
          title: 'FPSC Inspector Customs & Intelligence Officer',
          author: 'Sir Tariq',
          rating: 4.9,
          price: 'Rs 2,500',
          imagePath: 'assets/images/course4.jpg',
          category: 'FPSC',
          description:
              'Master all essential subjects for the FPSC Inspector Customs examination. Includes in-depth modules on Customs Act 1969, Pakistan Affairs, Everyday Science, General Knowledge, and comprehensive mock tests.',
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final isEnrolled = (_course.progress ?? 0) > 0;
    final isTeacher = ref.watch(authControllerProvider).value?.selectedRole == UserRole.teacher;

    return Scaffold(
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
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_shared_outlined, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Handouts & Notes',
                  onPressed: () {
                    CourseResourcesSheet.show(
                      context,
                      courseId: _course.id,
                      courseTitle: _course.title,
                      isTeacher: isTeacher,
                    );
                  },
                ),
                if (isTeacher)
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                    ),
                    tooltip: 'Learner Analytics',
                    onPressed: () {
                      context.pushNamed(AppRoute.teacherStudents.name, extra: _course.title);
                    },
                  ),
                SizedBox(width: 8.w),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _course.imagePath,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
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
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3.h,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey500,
                  labelStyle: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
                  unselectedLabelStyle: AppTextStyles.interMedium16.copyWith(fontSize: 14.sp),
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
            CourseOverviewTab(course: _course, isTeacher: isTeacher),
            CourseCurriculumTab(course: _course, isTeacher: isTeacher),
            CourseReviewsTab(
              courseId: _course.id,
              courseTitle: _course.title,
              isTeacher: isTeacher,
            ),
            CourseInstructorTab(course: _course),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.grey300, width: 1.w)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: isTeacher
              ? Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: _course.isPublished ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _course.isPublished ? '● Published' : '○ Draft',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 11.sp,
                              color: _course.isPublished ? const Color(0xFF10B981) : const Color(0xFFD97706),
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
                          context.pushNamed(AppRoute.teacherManageCourse.name, extra: _course);
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
                      child: CustomButton(
                        text: isEnrolled ? 'Continue Learning' : 'Enroll Now',
                        color: AppColors.primary,
                        onPressed: () {
                          if (isEnrolled) {
                            context.pushNamed(
                              AppRoute.lessonPlayer.name,
                              extra: {
                                'course': _course,
                                'lesson': _course.modules.isNotEmpty && _course.modules.first.lessons.isNotEmpty
                                    ? _course.modules.first.lessons.first
                                    : LessonModel(id: 'l1', title: 'Introduction', durationMinutes: 15),
                              },
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CourseEnrollModal(course: _course),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
