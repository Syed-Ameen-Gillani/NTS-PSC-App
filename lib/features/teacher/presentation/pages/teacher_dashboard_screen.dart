import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16.w),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 20.sp,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Educora Studio',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.verified, color: AppColors.primary, size: 14.w),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Sir Tariq Mahmood',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 22.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24.r,
                        backgroundImage: const AssetImage('assets/images/teacher1.png'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Earnings Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E75F1), Color(0xFF0F4DB8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accrued Course Royalties',
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 13.sp,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              state.stats.totalEarnings,
                              style: AppTextStyles.interBold30.copyWith(
                                fontSize: 26.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => context.pushNamed(AppRoute.teacherPayouts.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          ),
                          child: Text(
                            'Payouts',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 2x2 Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.pushNamed(AppRoute.teacherStudents.name),
                          child: _buildStatCard(
                            title: 'Enrolled Students',
                            value: '${state.stats.totalStudents}',
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                            bgColor: const Color(0xFFE3F2FD),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Active Courses',
                          value: '${state.stats.activeCourses}',
                          icon: Icons.school_outlined,
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Mock Quizzes',
                          value: '${state.stats.totalQuizzes}',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Student Rating',
                          value: '${state.stats.avgRating} ★',
                          icon: Icons.star_outline,
                          color: const Color(0xFF8B5CF6),
                          bgColor: const Color(0xFFEDE9FE),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  // Quick Actions
                  Text(
                    'Instructor Quick Actions',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 17.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherCreateCourse.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.add_to_photos_rounded, color: AppColors.primary, size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  '+ Course',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherCreateQuiz.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, color: Colors.orange, size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  '+ Quiz',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherAnalytics.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.analytics_outlined, color: Colors.purple, size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  'Analytics',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherLiveClasses.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.videocam_outlined, color: Colors.red, size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  'Live Classes',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherDoubts.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.question_answer_outlined, color: const Color(0xFF10B981), size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  'Q&A Doubts',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.pushNamed(AppRoute.teacherStudents.name),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.w),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 24.w),
                                SizedBox(height: 6.h),
                                Text(
                                  'Roster',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  // Recent Enrollments
                  Text(
                    'Recent Student Enrollments',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 17.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildEnrollmentItem('Hamza Tariq', 'FPSC Inspector Customs', '10 mins ago'),
                  _buildEnrollmentItem('Ayesha Siddiqa', 'AJK PSC General Masterclass', '1 hour ago'),
                  _buildEnrollmentItem('Bilal Hassan', 'Everyday Science Complete', '3 hours ago'),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading teacher dashboard')),
        ),
      ),
    );
  }

  Widget _buildEnrollmentItem(String student, String course, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person, color: AppColors.primary, size: 18.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                Text(
                  course,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 11.sp,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}
