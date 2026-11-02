import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_lesson_screen.dart';

class LessonAuthoringSheet extends StatelessWidget {
  const LessonAuthoringSheet({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  final String courseId;
  final String moduleId;

  static Future<LessonModel?> show(
    BuildContext context,
    String courseId,
    String moduleId,
  ) => showModalBottomSheet<LessonModel>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => LessonAuthoringSheet(
      courseId: courseId,
      moduleId: moduleId,
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: EdgeInsets.only(top: 52.h),
        child: TeacherCreateLessonScreen(
          courseId: courseId,
          moduleId: moduleId,
        ),
      ),
      Positioned(
        top: 0,
        right: 20.w,
        child: Material(
          color: AppColors.grey100,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.grey300),
          ),
          child: SizedBox.square(
            dimension: 40.r,
            child: IconButton(
              tooltip: 'Close',
              icon: Icon(
                Icons.close_rounded,
                size: 20.r,
                color: AppColors.grey700,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                }
              },
            ),
          ),
        ),
      ),
    ],
  );
}
