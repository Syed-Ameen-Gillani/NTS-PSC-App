import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/services/app_image_picker_service.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/features/teacher/data/course_cover_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _coverBusyProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);

class CourseCoverUploadButton extends ConsumerWidget {
  const CourseCoverUploadButton({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(_coverBusyProvider(courseId));
    return TextButton.icon(
      style: TextButton.styleFrom(
        textStyle: AppTextStyles.interMedium16.copyWith(fontSize: 13.sp),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      icon: Icon(
        busy ? Icons.hourglass_top : Icons.add_photo_alternate_outlined,
      ),
      label: Text(busy ? 'Uploading cover...' : 'Upload course cover'),
      onPressed: busy
          ? null
          : () async {
              final repository = ref.read(courseCoverRepositoryProvider);
              ref.read(_coverBusyProvider(courseId).notifier).state = true;
              try {
                final image = await ref
                    .read(appImagePickerServiceProvider)
                    .pickAndCrop(
                      context: context,
                      preset: AppImageCropPreset.courseCover,
                    );
                if (image == null) return;
                final coverUrl = await repository.upload(courseId, image.bytes);
                if (!context.mounted) return;
                ref
                    .read(teacherControllerProvider.notifier)
                    .updateCourseCover(courseId, coverUrl);
                CustomToast.showSuccess(
                  context,
                  message: 'Course cover saved.',
                );
              } catch (error) {
                if (!context.mounted) return;
                CustomToast.showError(
                  context,
                  message: error is ArgumentError
                      ? error.message.toString()
                      : error is PostgrestException
                      ? error.message
                      : 'Could not upload the cover. Choose a valid image and retry.',
                );
              } finally {
                if (context.mounted) {
                  ref.read(_coverBusyProvider(courseId).notifier).state = false;
                }
              }
            },
    );
  }
}
