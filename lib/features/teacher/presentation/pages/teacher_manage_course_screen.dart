import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_course_workspace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_authoring_sheet.dart';
import 'package:nts_psc_app/presentation/widgets/custom_confirmation_dialog.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherManageCourseScreen extends ConsumerStatefulWidget {
  final CourseModel course;

  const TeacherManageCourseScreen({super.key, required this.course});

  @override
  ConsumerState<TeacherManageCourseScreen> createState() =>
      _TeacherManageCourseScreenState();
}

class _TeacherManageCourseScreenState
    extends ConsumerState<TeacherManageCourseScreen> {
  void _showAddModuleDialog(BuildContext context, String courseId) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Add New Module',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Title',
              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp),
            ),
            SizedBox(height: 6.h),
            CustomTextFormField(
              controller: titleController,
              hintText: 'e.g. Module 3: Constitutional Law & Rights',
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.interMedium16.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                try {
                  await ref
                      .read(teacherControllerProvider.notifier)
                      .addModule(courseId, titleController.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    CustomToast.showSuccess(
                      context,
                      message: 'Module added to curriculum!',
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    CustomToast.showError(
                      context,
                      message: error is PostgrestException
                          ? error.message
                          : 'Could not add module',
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Add Module',
              style: AppTextStyles.interSemiBold16.copyWith(
                color: Colors.white,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(
    BuildContext context,
    String courseId,
    String moduleId,
  ) {
    LessonAuthoringSheet.show(context, courseId, moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);
    final assignmentsState = ref.watch(assignmentsControllerProvider).value;

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Course Studio',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Delete course',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CustomConfirmationDialog(
                  title: 'Delete Course',
                  content:
                      'Are you sure you want to delete this course? Enrolled students will lose access.',
                  confirmText: 'Delete',
                  cancelText: 'Cancel',
                  isDestructive: true,
                  onConfirm: () async {
                    try {
                      await ref
                          .read(teacherControllerProvider.notifier)
                          .deleteCourse(widget.course.id);
                      if (context.mounted) {
                        CustomToast.showSuccess(
                          context,
                          message: 'Course deleted.',
                        );
                        context.pop();
                      }
                    } catch (_) {
                      if (context.mounted) {
                        CustomToast.showError(
                          context,
                          message: 'Could not delete course',
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: teacherState.when(
        data: (state) {
          final liveCourse = state.courses.firstWhere(
            (c) => c.id == widget.course.id,
            orElse: () => widget.course,
          );
          final assignmentCount =
              assignmentsState?.assignments
                  .where((item) => item.courseId == liveCourse.id)
                  .length ??
              0;
          final quizCount = state.quizzes
              .where((item) => item.courseId == liveCourse.id)
              .length;
          return TeacherCourseWorkspace(
            course: liveCourse,
            assessmentCount: assignmentCount + quizCount,
            onAddModule: () => _showAddModuleDialog(context, liveCourse.id),
            onAddLesson: (moduleId) =>
                _showAddLessonDialog(context, liveCourse.id, moduleId),
            onPublish: (value) async {
              try {
                final changed = await ref
                    .read(teacherControllerProvider.notifier)
                    .togglePublishCourse(liveCourse.id);
                if (context.mounted) {
                  CustomToast.showSuccess(
                    context,
                    message: value
                        ? 'Course published.'
                        : changed
                        ? 'Course changes published.'
                        : 'Course is up to date.',
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  CustomToast.showError(
                    context,
                    message: error is PostgrestException
                        ? error.message
                        : 'Could not update course',
                  );
                }
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error loading course details')),
      ),
    );
  }
}
