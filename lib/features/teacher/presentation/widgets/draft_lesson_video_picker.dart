import 'dart:io';
import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_preparer.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

typedef DraftLessonVideo = ({String path, String name, String mimeType});
typedef DraftVideoProgress = ({String label, double value});

final draftLessonVideoProvider = StateProvider.autoDispose
    .family<DraftLessonVideo?, String>((ref, id) => null);
final draftVideoProgressProvider = StateProvider.autoDispose
    .family<DraftVideoProgress?, String>((ref, id) => null);

class DraftLessonVideoPicker extends ConsumerWidget {
  const DraftLessonVideoPicker({
    super.key,
    required this.draftId,
    required this.busy,
  });

  final String draftId;
  final bool busy;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    try {
      developer.log(
        'Opening video picker for lesson draft $draftId.',
        name: 'CBOA.VideoUpload',
      );
      final file = await FilePicker.pickFile(type: FileType.video);
      if (file == null) {
        developer.log(
          'Video picker was cancelled for lesson draft $draftId.',
          name: 'CBOA.VideoUpload',
        );
        return;
      }
      if (!context.mounted) return;
      final path = file.path;
      developer.log(
        'Video selected: name=${file.name}, extension=${file.extension}, '
        'path=${path ?? '<unavailable>'}.',
        name: 'CBOA.VideoUpload',
      );
      final mime = switch (file.extension?.toLowerCase()) {
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => null,
      };
      if (path == null || mime == null) {
        throw ArgumentError('Choose an MP4, WebM, or MOV video.');
      }
      final size = await File(path).length();
      developer.log(
        'Selected video metadata: mime=$mime, bytes=$size, '
        'exists=${await File(path).exists()}.',
        name: 'CBOA.VideoUpload',
      );
      if (size < 1 || size > maxLessonSourceBytes) {
        throw ArgumentError('Choose a video smaller than 250 MB.');
      }
      if (!context.mounted) return;
      ref.read(draftLessonVideoProvider(draftId).notifier).state = (
        path: path,
        name: file.name,
        mimeType: mime,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Video selection failed for lesson draft $draftId.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : 'Could not select this video.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(draftLessonVideoProvider(draftId));
    final progress = ref.watch(draftVideoProgressProvider(draftId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected == null)
          InkWell(
            onTap: busy ? null : () => _pick(context, ref),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.grey300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(
                      Icons.video_call_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add lesson video (optional)',
                          style: AppTextStyles.interMedium16.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'MP4, WebM, or MOV up to 250 MB',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: busy ? null : () => _pick(context, ref),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: const Text('Browse'),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Ready to upload with lesson',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 11.sp,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove selected video',
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.grey600,
                  onPressed: busy
                      ? null
                      : () =>
                            ref
                                    .read(
                                      draftLessonVideoProvider(
                                        draftId,
                                      ).notifier,
                                    )
                                    .state =
                                null,
                ),
              ],
            ),
          ),
        if (progress != null) ...[
          SizedBox(height: 8.h),
          Text(
            '${progress.label} ${(progress.value * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(value: progress.value),
        ],
      ],
    );
  }
}
