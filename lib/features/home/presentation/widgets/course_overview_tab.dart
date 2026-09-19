import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_certificate_dialog.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';

class CourseOverviewTab extends ConsumerWidget {
  final CourseModel course;
  final bool isTeacher;

  const CourseOverviewTab({
    super.key,
    required this.course,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref
        .watch(courseCommunityProvider)
        .announcements
        .where((a) => a.courseId == course.id)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcements.isNotEmpty) ...[
            _buildAnnouncementBanner(announcements.first),
            SizedBox(height: 16.h),
          ],
          Text(
            'About This Course',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            course.description.isNotEmpty
                ? course.description
                : 'Complete syllabus preparation with expert guidance, past papers practice, and test simulations tailored for high scores in competitive examinations.',
            style: AppTextStyles.interRegular16.copyWith(
              fontSize: 14.sp,
              color: AppColors.grey700,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'What You Will Learn',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 12.h),
          _buildLearningPoint('Complete coverage of Customs Act 1969 (Sections 1 to 223)'),
          _buildLearningPoint('High-frequency MCQs in Pakistan Affairs & Current Affairs'),
          _buildLearningPoint('Everyday Science physical, biological, and environmental concepts'),
          _buildLearningPoint('Mock tests with real-time scoring and answer explanations'),
          SizedBox(height: 20.h),
          Text(
            'Course Statistics',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildStatChip(Icons.people_outline, '${course.enrolledCount}+ Students'),
              _buildStatChip(Icons.star_rounded, '${course.rating} Rating'),
              _buildStatChip(Icons.play_circle_outline, '18 Lectures'),
            ],
          ),
          SizedBox(height: 16.h),
          _buildActionBanner(
            icon: Icons.folder_shared_outlined,
            title: 'Course Handouts & Past Papers',
            subtitle: 'Download official PDF gazettes and lecture summaries',
            buttonLabel: 'Files',
            onTap: () => CourseResourcesSheet.show(
              context,
              courseId: course.id,
              courseTitle: course.title,
              isTeacher: isTeacher,
            ),
          ),
          SizedBox(height: 12.h),
          _buildActionBanner(
            icon: Icons.workspace_premium_outlined,
            title: 'Verified Certificate of Completion',
            subtitle: 'Official credential with verification hash upon passing',
            buttonLabel: 'Preview',
            onTap: () {
              final studentName = ref.read(authControllerProvider).value?.user?.name ?? 'Syed Ameen';
              CourseCertificateDialog.show(
                context,
                studentName: studentName,
                courseTitle: course.title,
                instructorName: course.author,
              );
            },
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner(dynamic ann) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.primary, size: 18.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  ann.title as String,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 13.sp,
                    color: const Color(0xFF1E3A8A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            ann.message as String,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF1E40AF),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200, width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 18.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 14.sp,
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}
