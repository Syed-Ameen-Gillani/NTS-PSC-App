import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CourseCurriculumTab extends StatelessWidget {
  final CourseModel course;
  final bool isTeacher;

  const CourseCurriculumTab({
    super.key,
    required this.course,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    final modules = course.modules.isNotEmpty
        ? course.modules
        : [
            CourseModuleModel(
              id: 'm1',
              title: 'Module 1: Orientation & Foundations',
              lessons: [
                LessonModel(
                  id: 'l1',
                  title: 'Comprehensive Syllabus & Test Blueprint Breakdown',
                  durationMinutes: 20,
                  isCompleted: true,
                ),
                LessonModel(
                  id: 'l2',
                  title: 'Core Concepts & Analytical Frameworks',
                  durationMinutes: 28,
                  isCompleted: false,
                ),
              ],
            ),
            CourseModuleModel(
              id: 'm2',
              title: 'Module 2: Advanced Topics & High-Yield MCQs',
              lessons: [
                LessonModel(
                  id: 'l3',
                  title: 'Past 10 Years Solved Questions & Strategy',
                  durationMinutes: 35,
                  isCompleted: false,
                ),
              ],
            ),
          ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: modules.length,
      itemBuilder: (context, moduleIndex) {
        final module = modules[moduleIndex];
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Material(
            color: const Color(0xFFF8F9FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: AppColors.grey300, width: 1.w),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: moduleIndex == 0,
                title: Text(
                  module.title,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                subtitle: Text(
                  '${module.lessons.length} Lessons',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),
                children: module.lessons.map((lesson) {
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16.r,
                        backgroundColor: lesson.isCompleted
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surface,
                        child: Icon(
                          lesson.isCompleted ? Icons.check : Icons.play_arrow_rounded,
                          color: lesson.isCompleted ? AppColors.success : AppColors.primary,
                          size: 18.w,
                        ),
                      ),
                      title: Text(
                        lesson.title,
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      trailing: Text(
                        '${lesson.durationMinutes} min',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey500,
                        ),
                      ),
                      onTap: () {
                        context.pushNamed(
                          AppRoute.lessonPlayer.name,
                          extra: {
                            'course': course,
                            'lesson': lesson,
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
