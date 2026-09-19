import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class StudentPerformanceSheet extends ConsumerWidget {
  final StudentRosterModel student;

  const StudentPerformanceSheet({super.key, required this.student});

  static void show(BuildContext context, StudentRosterModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentPerformanceSheet(student: student),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController(
      text: student.status == 'Needs Attention'
          ? 'Hi ${student.name}, I noticed you are falling slightly behind on recent lectures. Feel free to review the module notes or ask any doubts in our Q&A forum!'
          : 'Great consistency on ${student.courseTitle}! Keep up the strong momentum on your upcoming mock tests.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Message ${student.name}',
          style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send personalized academic guidance or study advice:',
              style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500),
            ),
            SizedBox(height: 12.h),
            CustomTextFormField(
              controller: messageController,
              maxLines: 3,
              hintText: 'Type your feedback...',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500, fontSize: 13.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              CustomToast.showSuccess(
                context,
                message: 'Academic note sent to ${student.name}!',
              );
            },
            child: Text(
              'Send Message',
              style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNudged = student.lastNudgedAt != null;
    final isAtRisk = student.status == 'Needs Attention';
    final isCompleted = student.status == 'Completed';

    Color statusColor;
    Color statusBgColor;
    if (isAtRisk) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (isCompleted) {
      statusColor = const Color(0xFF2563EB);
      statusBgColor = const Color(0xFFDBEAFE);
    } else {
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFD1FAE5);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag Handle
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // Header with Close
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learner Diagnostics',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Coursera-Style Performance Report',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grey500),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.grey300, height: 16.h),

          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              children: [
                // Student Profile Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26.r,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          student.name.isNotEmpty ? student.name[0] : 'S',
                          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    student.name,
                                    style: AppTextStyles.interSemiBold16.copyWith(fontSize: 15.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    student.status,
                                    style: AppTextStyles.interSemiBold16.copyWith(
                                      fontSize: 10.sp,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              student.email,
                              style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500),
                            ),
                            SizedBox(height: 6.h),
                            Wrap(
                              spacing: 12.w,
                              runSpacing: 6.h,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 12.w, color: AppColors.grey500),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        'Joined ${student.enrolledAt}',
                                        style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 12.w, color: AppColors.grey500),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        'Active ${student.lastActive}',
                                        style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Course Enrolled In
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 18.w, color: AppColors.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          student.courseTitle,
                          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // Syllabus & Completion Progress
                Text(
                  'Curriculum Completion',
                  style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp, color: AppColors.onBackground),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${student.completedLessons} of ${student.totalLessons} Lessons Watched',
                            style: AppTextStyles.interMedium16.copyWith(fontSize: 12.sp, color: AppColors.grey700),
                          ),
                          Text(
                            '${(student.progress * 100).toInt()}%',
                            style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp, color: AppColors.primary),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: student.progress,
                          backgroundColor: AppColors.grey300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAtRisk ? const Color(0xFFD97706) : AppColors.primary,
                          ),
                          minHeight: 8.h,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // Assessments & Quiz Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assessment History',
                      style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp, color: AppColors.onBackground),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: student.averageQuizScore >= 60 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Avg Score: ${student.averageQuizScore}%',
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 11.sp,
                          color: student.averageQuizScore >= 60 ? const Color(0xFF065F46) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                if (student.quizBreakdown.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Center(
                      child: Text(
                        'No quizzes submitted yet.',
                        style: AppTextStyles.interRegular14.copyWith(color: AppColors.grey500, fontSize: 12.sp),
                      ),
                    ),
                  )
                else
                  ...student.quizBreakdown.map((quiz) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: quiz.passed ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              quiz.passed ? Icons.check_circle_outline : Icons.highlight_off,
                              size: 16.w,
                              color: quiz.passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.quizTitle,
                                  style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Completed: ${quiz.date}',
                                  style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${quiz.score}%',
                                style: AppTextStyles.interBold24.copyWith(
                                  fontSize: 15.sp,
                                  color: quiz.passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                quiz.passed ? 'PASSED' : 'NEEDS RETAKE',
                                style: AppTextStyles.interSemiBold16.copyWith(
                                  fontSize: 9.sp,
                                  color: quiz.passed ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                SizedBox(height: 24.h),
              ],
            ),
          ),

          // Bottom Action Bar: Coursera Intervention Actions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey300, width: 1.w)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: () => _showFeedbackDialog(context, ref),
                    icon: Icon(Icons.chat_bubble_outline, size: 16.w, color: AppColors.primary),
                    label: Text(
                      'Direct Feedback',
                      style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp, color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomButton(
                    text: isNudged ? 'Nudge Sent Today' : 'Send Study Nudge',
                    color: isNudged ? AppColors.grey500 : (isAtRisk ? const Color(0xFFD97706) : AppColors.primary),
                    height: 44.h,
                    onPressed: () {
                      ref.read(teacherControllerProvider.notifier).sendStudentNudge(student.id);
                      Navigator.pop(context);
                      CustomToast.showSuccess(
                        context,
                        message: 'Study reminder & motivational nudge sent to ${student.name}!',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
