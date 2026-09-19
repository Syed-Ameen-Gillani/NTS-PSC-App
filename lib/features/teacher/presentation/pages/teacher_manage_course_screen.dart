import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/broadcast_announcement_dialog.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_confirmation_dialog.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherManageCourseScreen extends ConsumerStatefulWidget {
  final CourseModel course;

  const TeacherManageCourseScreen({super.key, required this.course});

  @override
  ConsumerState<TeacherManageCourseScreen> createState() => _TeacherManageCourseScreenState();
}

class _TeacherManageCourseScreenState extends ConsumerState<TeacherManageCourseScreen> {
  void _showAddModuleDialog(BuildContext context, String courseId) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Add New Module', style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Module Title', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
            SizedBox(height: 6.h),
            CustomTextFormField(
              controller: titleController,
              hintText: 'e.g. Module 3: Constitutional Law & Rights',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(teacherControllerProvider.notifier).addModule(courseId, titleController.text.trim());
                Navigator.pop(ctx);
                CustomToast.showSuccess(context, message: 'Module added to curriculum!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text('Add Module', style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context, String courseId, String moduleId) {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '20');
    final videoUrlController = TextEditingController(text: 'https://youtube.com/watch?v=mock');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 24.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Lecture / Lesson', style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Lesson Title', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: titleController, hintText: 'e.g. Fundamental Rights in 1973 Constitution'),
              SizedBox(height: 12.h),
              Text('Duration (Minutes)', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: durationController, hintText: '25', keyboardType: TextInputType.number),
              SizedBox(height: 12.h),
              Text('Video Stream / Lecture URL', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: videoUrlController, hintText: 'https://...'),
              SizedBox(height: 12.h),
              Text('Study Notes & Reading Material', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: notesController, hintText: 'Key bullet points, past questions...', maxLines: 2),
              SizedBox(height: 20.h),
              CustomButton(
                text: 'Publish Lesson',
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final newLesson = LessonModel(
                      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      durationMinutes: int.tryParse(durationController.text.trim()) ?? 20,
                      videoUrl: videoUrlController.text.trim(),
                      notes: notesController.text.trim(),
                    );
                    ref.read(teacherControllerProvider.notifier).addLesson(courseId, moduleId, newLesson);
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, message: 'Lesson published successfully!');
                  }
                },
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Course Studio',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: AppColors.onBackground),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CustomConfirmationDialog(
                  title: 'Delete Course',
                  content: 'Are you sure you want to delete this course? Enrolled students will lose access.',
                  confirmText: 'Delete',
                  cancelText: 'Cancel',
                  isDestructive: true,
                  onConfirm: () {
                    ref.read(teacherControllerProvider.notifier).deleteCourse(widget.course.id);
                    context.pop();
                    CustomToast.showSuccess(context, message: 'Course deleted.');
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

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: liveCourse.isPublished ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              liveCourse.isPublished ? '● Published' : '● Draft Mode',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 11.sp,
                                color: liveCourse.isPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: liveCourse.isPublished,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(teacherControllerProvider.notifier).togglePublishCourse(liveCourse.id);
                              CustomToast.showSuccess(
                                context,
                                message: val ? 'Course published to student catalog!' : 'Course moved to drafts.',
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(liveCourse.title, style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
                      SizedBox(height: 4.h),
                      Text('Category: ${liveCourse.category} • Price: ${liveCourse.price}',
                          style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500)),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 16.w, color: AppColors.primary),
                          SizedBox(width: 4.w),
                          Text('${liveCourse.enrolledCount} Students Enrolled',
                              style: AppTextStyles.interMedium16.copyWith(fontSize: 12.sp, color: AppColors.onBackground)),
                          SizedBox(width: 16.w),
                          Icon(Icons.star, size: 16.w, color: Colors.amber),
                          SizedBox(width: 4.w),
                          Text('${liveCourse.rating} Rating',
                              style: AppTextStyles.interMedium16.copyWith(fontSize: 12.sp, color: AppColors.onBackground)),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 38.h),
                          side: BorderSide(color: AppColors.primary, width: 1.w),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        onPressed: () {
                          context.pushNamed(AppRoute.teacherStudents.name, extra: liveCourse.title);
                        },
                        icon: Icon(Icons.analytics_outlined, size: 16.w, color: AppColors.primary),
                        label: Text(
                          'View Enrolled Learners & Diagnostics',
                          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp, color: AppColors.primary),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(0, 36.h),
                                side: BorderSide(color: const Color(0xFF2563EB), width: 1.w),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              ),
                              onPressed: () {
                                BroadcastAnnouncementDialog.show(
                                  context,
                                  courseId: liveCourse.id,
                                  courseTitle: liveCourse.title,
                                );
                              },
                              icon: Icon(Icons.campaign_outlined, size: 16.w, color: const Color(0xFF2563EB)),
                              label: Text(
                                'Broadcast',
                                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(0, 36.h),
                                side: BorderSide(color: const Color(0xFF059669), width: 1.w),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                              ),
                              onPressed: () {
                                CourseResourcesSheet.show(
                                  context,
                                  courseId: liveCourse.id,
                                  courseTitle: liveCourse.title,
                                  isTeacher: true,
                                );
                              },
                              icon: Icon(Icons.folder_shared_outlined, size: 16.w, color: const Color(0xFF059669)),
                              label: Text(
                                'Handouts',
                                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Curriculum Builder Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Curriculum & Syllabus', style: AppTextStyles.interBold24.copyWith(fontSize: 17.sp)),
                    ElevatedButton.icon(
                      onPressed: () => _showAddModuleDialog(context, liveCourse.id),
                      icon: Icon(Icons.add, size: 16.w, color: Colors.white),
                      label: Text('Add Module', style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 12.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Modules & Lessons List
                if (liveCourse.modules.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.menu_book, size: 36.w, color: AppColors.grey400),
                        SizedBox(height: 8.h),
                        Text('No curriculum modules yet.', style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500)),
                        SizedBox(height: 12.h),
                        OutlinedButton(
                          onPressed: () => _showAddModuleDialog(context, liveCourse.id),
                          child: const Text('+ Add First Module'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveCourse.modules.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, mIdx) {
                      final module = liveCourse.modules[mIdx];
                      return Material(
                        color: const Color(0xFFF8F9FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(color: AppColors.grey300, width: 1.w),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(module.title, style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp)),
                          subtitle: Text('${module.lessons.length} Lectures',
                              style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500)),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            onPressed: () => _showAddLessonDialog(context, liveCourse.id, module.id),
                          ),
                          children: [
                            if (module.lessons.isEmpty)
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Text('No lessons yet in this module. Tap + to add.',
                                    style: AppTextStyles.interRegular14.copyWith(color: AppColors.grey500, fontSize: 12.sp)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: module.lessons.length,
                                itemBuilder: (context, lIdx) {
                                  final lesson = module.lessons[lIdx];
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 14.r,
                                        backgroundColor: AppColors.surface,
                                        child: Text('${lIdx + 1}',
                                            style: AppTextStyles.interSemiBold16.copyWith(fontSize: 11.sp, color: AppColors.primary)),
                                      ),
                                      title: Text(lesson.title, style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                                      subtitle: Text('${lesson.durationMinutes} mins • Video Stream',
                                          style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500)),
                                      trailing: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading course details')),
      ),
    );
  }
}
