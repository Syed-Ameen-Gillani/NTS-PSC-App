import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_resources_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/models/course_community_models.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

class CourseResourcesSheet extends ConsumerWidget {
  final String courseId;
  final String courseTitle;
  final bool isTeacher;

  const CourseResourcesSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.isTeacher = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    required String courseTitle,
    bool isTeacher = false,
  }) {
    if (AppConfig.isSupabaseEnabled) {
      return context.pushNamed<void>(
        AppRoute.curriculumResources.name,
        extra: CurriculumScope(courseId: courseId),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseResourcesSheet(
        courseId: courseId,
        courseTitle: courseTitle,
        isTeacher: isTeacher,
      ),
    );
  }

  void _showAddHandoutDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final moduleController = TextEditingController(
      text: 'Module 1: High-Yield Revision',
    );
    String selectedType = 'PDF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Upload Handout / Past Paper',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onTapOutside: dismissKeyboardOnTapOutside,
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'e.g. Customs Act 1969 High-Frequency Summary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                onTapOutside: dismissKeyboardOnTapOutside,
                controller: moduleController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Module / Topic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: AppColors.background,
                focusColor: AppColors.surface,
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.onBackground,
                ),
                decoration: InputDecoration(
                  labelText: 'File Format',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PDF',
                    child: Text('PDF Document (.pdf)'),
                  ),
                  DropdownMenuItem(
                    value: 'SLIDES',
                    child: Text('Presentation Slides (.pptx)'),
                  ),
                  DropdownMenuItem(
                    value: 'DOC',
                    child: Text('Word Handout (.docx)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                ref
                    .read(courseCommunityProvider.notifier)
                    .addResource(
                      courseId: courseId,
                      moduleTitle: moduleController.text.trim(),
                      title: title,
                      fileType: selectedType,
                      fileSize: '3.4 MB',
                    );
                Navigator.pop(ctx);
                CustomToast.showSuccess(
                  context,
                  message:
                      'Handout successfully attached to course curriculum!',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text(
                'Upload Handout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled) {
      return CurriculumResourcesScreen(
        scope: CurriculumScope(courseId: courseId),
      );
    }
    final resources = ref
        .watch(courseCommunityProvider)
        .resources
        .where((r) => r.courseId == courseId)
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 0.85.sh),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Handouts & Materials',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${resources.length} study files available for download',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTeacher)
                IconButton(
                  onPressed: () => _showAddHandoutDialog(context, ref),
                  icon: Icon(
                    Icons.add_circle,
                    color: AppColors.primary,
                    size: 28.w,
                  ),
                  tooltip: 'Add Handout',
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: resources.isEmpty
                ? Center(
                    child: Text(
                      'No handouts uploaded yet.',
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: resources.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final item = resources[index];
                      return _buildResourceTile(context, ref, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile(
    BuildContext context,
    WidgetRef ref,
    CourseResourceModel item,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: item.fileType == 'PDF'
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              item.fileType == 'PDF'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.slideshow_rounded,
              color: item.fileType == 'PDF'
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2563EB),
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.onBackground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${item.moduleTitle} • ${item.fileSize}',
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
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(courseCommunityProvider.notifier)
                  .toggleResourceDownload(item.id);
              CustomToast.showSuccess(
                context,
                message: item.isDownloaded
                    ? 'File opened from device storage.'
                    : 'Downloading ${item.title}... Saved to Downloads!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: item.isDownloaded
                  ? const Color(0xFFECFDF5)
                  : AppColors.primary,
              foregroundColor: item.isDownloaded
                  ? const Color(0xFF059669)
                  : Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isDownloaded
                      ? Icons.check_circle_outline
                      : Icons.download_rounded,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Text(
                  item.isDownloaded ? 'Open' : 'Save',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
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
