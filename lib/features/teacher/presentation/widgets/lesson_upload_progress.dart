import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_preparer.dart';

Future<bool> confirmVideoPreparationCancellation(
  BuildContext context, {
  bool uploading = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          uploading ? 'Cancel video upload?' : 'Cancel video preparation?',
        ),
        content: Text(
          uploading
              ? 'Stop uploading this video? You can select it again.'
              : 'Stop preparing this video? You can select a video again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(uploading ? 'Keep uploading' : 'Keep preparing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(uploading ? 'Cancel upload' : 'Cancel preparation'),
          ),
        ],
      ),
    ) ??
    false;

class LessonUploadProgressValue {
  const LessonUploadProgressValue({
    required this.label,
    required this.value,
    this.originalBytes,
    this.expectedBytes,
    this.indeterminate = false,
  });

  final String label;
  final double value;
  final int? originalBytes;
  final int? expectedBytes;
  final bool indeterminate;

  LessonUploadProgressValue copyWith({
    String? label,
    double? value,
    int? originalBytes,
    int? expectedBytes,
    bool? indeterminate,
  }) => LessonUploadProgressValue(
    label: label ?? this.label,
    value: value ?? this.value,
    originalBytes: originalBytes ?? this.originalBytes,
    expectedBytes: expectedBytes ?? this.expectedBytes,
    indeterminate: indeterminate ?? this.indeterminate,
  );
}

class LessonUploadProgress extends StatelessWidget {
  const LessonUploadProgress({super.key, required this.progress});

  final ValueNotifier<LessonUploadProgressValue?> progress;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: progress,
    builder: (context, value, _) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: LessonUploadProgressDetails(value: value),
          ),
  );
}

class LessonUploadProgressDetails extends StatelessWidget {
  const LessonUploadProgressDetails({
    super.key,
    required this.value,
    this.showCancel = false,
    this.onCancel,
    this.icon = Icons.video_file_outlined,
    this.originalLabel = 'Original',
  });

  final LessonUploadProgressValue value;
  final bool showCancel;
  final VoidCallback? onCancel;
  final IconData icon;
  final String originalLabel;

  @override
  Widget build(BuildContext context) {
    final expectedBytes = value.expectedBytes;
    final isCancelling = value.label == 'Cancelling…';
    final indeterminate =
        value.indeterminate || value.label == 'Preparing video' || isCancelling;
    final withinLimit =
        expectedBytes != null && expectedBytes <= maxPreparedLessonBytes;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.w, color: AppColors.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                value.label,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (showCancel && !isCancelling) ...[
              SizedBox(width: 4.w),
              SizedBox.square(
                dimension: 28.w,
                child: IconButton(
                  tooltip: value.label == 'Uploading video'
                      ? 'Cancel upload'
                      : 'Cancel preparation',
                  padding: EdgeInsets.zero,
                  onPressed: onCancel,
                  icon: Icon(Icons.close_rounded, size: 17.w),
                  color: AppColors.grey600,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: indeterminate ? null : value.value.clamp(0, 1),
                  minHeight: 4.h,
                  backgroundColor: AppColors.grey200,
                ),
              ),
            ),
            if (!indeterminate) ...[
              SizedBox(width: 10.w),
              SizedBox(
                width: 34.w,
                child: Text(
                  '${(value.value.clamp(0, 1) * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 11.sp,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!isCancelling &&
            (value.originalBytes != null || expectedBytes != null)) ...[
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value.originalBytes != null)
                Expanded(
                  child: _SizeMetric(
                    label: originalLabel,
                    value: _formatBytes(value.originalBytes!),
                  ),
                ),
              if (value.originalBytes != null && expectedBytes != null)
                SizedBox(width: 16.w),
              if (expectedBytes != null)
                Expanded(
                  child: _SizeMetric(
                    label: value.label == 'Uploading video'
                        ? 'Compressed size'
                        : 'Expected size',
                    value: _formatBytes(expectedBytes),
                    alignEnd: true,
                  ),
                ),
            ],
          ),
        ],
        if (!isCancelling && expectedBytes != null && !withinLimit) ...[
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, size: 16.w, color: colors.error),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Expected output may exceed 25 MB. A shorter video may be required.',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 11.sp,
                    height: 1.35,
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _formatBytes(int bytes) {
    const bytesPerMegabyte = 1024 * 1024;
    return '${(bytes / bytesPerMegabyte).toStringAsFixed(1)} MB';
  }
}

class _SizeMetric extends StatelessWidget {
  const _SizeMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: AppTextStyles.interRegular14.copyWith(
          fontSize: 11.sp,
          color: AppColors.grey600,
        ),
      ),
      SizedBox(height: 2.h),
      Text(
        value,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: AppTextStyles.interSemiBold16.copyWith(
          fontSize: 11.sp,
          color: AppColors.onBackground,
        ),
      ),
    ],
  );
}
