import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/services/app_image_picker_service.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

typedef DraftCourseCover = ({String name, Uint8List bytes});

final draftCourseCoverProvider = StateProvider.autoDispose
    .family<DraftCourseCover?, String>((ref, id) => null);
final draftCourseCoverErrorProvider = StateProvider.autoDispose
    .family<bool, String>((ref, id) => false);

class DraftCourseCoverPicker extends ConsumerWidget {
  const DraftCourseCoverPicker({
    super.key,
    required this.draftId,
    required this.busy,
  });

  final String draftId;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(draftCourseCoverProvider(draftId));
    final showError = ref.watch(draftCourseCoverErrorProvider(draftId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.grey100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: showError ? AppColors.error : AppColors.grey300,
                width: 1.w,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy ? null : () => _pickCover(context, ref),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: selected == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 24.w,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Upload course cover',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: AppColors.primary,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'JPEG, PNG or WebP · Up to 5 MB',
                              style: AppTextStyles.interRegular14.copyWith(
                                color: AppColors.grey500,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Image.memory(
                              selected.bytes,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            right: 12.w,
                            bottom: 12.h,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              elevation: 2,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(20.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20.r),
                                onTap: busy
                                    ? null
                                    : () => _pickCover(context, ref),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.primary,
                                        size: 14.w,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Change cover',
                                        style: AppTextStyles.interSemiBold16
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontSize: 12.sp,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (showError) ...[
          SizedBox(height: 6.h),
          Text(
            'Please add a course cover',
            style: AppTextStyles.interRegular14.copyWith(
              color: AppColors.error,
              fontSize: 11.sp,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickCover(BuildContext context, WidgetRef ref) async {
    try {
      final image = await ref
          .read(appImagePickerServiceProvider)
          .pickAndCrop(
            context: context,
            preset: AppImageCropPreset.courseCover,
          );
      if (image == null || !context.mounted) return;
      ref.read(draftCourseCoverProvider(draftId).notifier).state = (
        name: image.name,
        bytes: image.bytes,
      );
      ref.read(draftCourseCoverErrorProvider(draftId).notifier).state = false;
    } catch (error) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : 'Could not select this image.',
        );
      }
    }
  }
}
