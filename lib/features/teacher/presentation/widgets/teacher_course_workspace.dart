import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/broadcast_announcement_dialog.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_header.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_module.dart';

class TeacherCourseWorkspace extends StatelessWidget {
  const TeacherCourseWorkspace({
    super.key,
    required this.course,
    required this.assessmentCount,
    required this.onPublish,
    required this.onAddModule,
    required this.onAddLesson,
  });
  final CourseModel course;
  final int assessmentCount;
  final Future<void> Function(bool) onPublish;
  final VoidCallback onAddModule;
  final ValueChanged<String> onAddLesson;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseWorkspaceHeader(course: course, onPublish: onPublish),
              SizedBox(height: 20.h),
              Row(
                children: [
                  _tool(
                    Icons.people_outline,
                    'Learners',
                    () => context.pushNamed(
                      AppRoute.teacherStudents.name,
                      extra: course.title,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _tool(
                    Icons.campaign_outlined,
                    'Broadcast',
                    () => BroadcastAnnouncementDialog.show(
                      context,
                      courseId: course.id,
                      courseTitle: course.title,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _tool(
                    Icons.folder_open_outlined,
                    'Handouts',
                    () => CourseResourcesSheet.show(
                      context,
                      courseId: course.id,
                      courseTitle: course.title,
                      isTeacher: true,
                    ),
                  ),
                ],
              ),
              Divider(height: 40.h, color: AppColors.grey200),
              _section(
                'Assessments',
                '$assessmentCount ${assessmentCount == 1 ? 'assessment' : 'assessments'}',
                TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: AppTextStyles.interMedium16.copyWith(
                      fontSize: 13.sp,
                    ),
                  ),
                  onPressed: () => context.pushNamed(
                    AppRoute.teacherCourseAssignments.name,
                    extra: course,
                  ),
                  icon: Icon(Icons.assignment_outlined, size: 18.w),
                  label: const Text('Manage'),
                ),
              ),
              Divider(height: 40.h, color: AppColors.grey200),
              _section(
                'Curriculum',
                '${course.modules.length} ${course.modules.length == 1 ? 'module' : 'modules'}',
                FilledButton.icon(
                  onPressed: onAddModule,
                  icon: Icon(Icons.add, size: 18.w),
                  label: const Text('Add module'),
                  style: FilledButton.styleFrom(
                    textStyle: AppTextStyles.interMedium16.copyWith(
                      fontSize: 13.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              if (course.modules.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Text(
                      'No modules added yet.',
                      style: AppTextStyles.interRegular14.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < course.modules.length; i++) ...[
                  CourseWorkspaceModule(
                    courseId: course.id,
                    module: course.modules[i],
                    index: i,
                    onAddLesson: () => onAddLesson(course.modules[i].id),
                  ),
                  SizedBox(height: 12.h),
                ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _section(String title, String subtitle, Widget action) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 17.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: 8.w),
      action,
    ],
  );

  Widget _tool(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.grey300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.w),
          SizedBox(height: 6.h),
          Text(
            label,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
