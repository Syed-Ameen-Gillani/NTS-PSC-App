import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_preparer.dart';

class LessonUploadProgressValue {
  const LessonUploadProgressValue({
    required this.label,
    required this.value,
    this.originalBytes,
    this.expectedBytes,
  });

  final String label;
  final double value;
  final int? originalBytes;
  final int? expectedBytes;

  LessonUploadProgressValue copyWith({
    String? label,
    double? value,
    int? originalBytes,
    int? expectedBytes,
  }) => LessonUploadProgressValue(
    label: label ?? this.label,
    value: value ?? this.value,
    originalBytes: originalBytes ?? this.originalBytes,
    expectedBytes: expectedBytes ?? this.expectedBytes,
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
  });

  final LessonUploadProgressValue value;
  final bool showCancel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final expectedBytes = value.expectedBytes;
    final withinLimit =
        expectedBytes != null && expectedBytes <= maxPreparedLessonBytes;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                value.label,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 13.sp,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (value.label != 'Preparing video' &&
                value.label != 'Cancelling…')
              Text(
                '${(value.value.clamp(0, 1) * 100).round()}%',
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 13.sp,
                  color: colors.primary,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value:
                      value.label == 'Preparing video' ||
                          value.label == 'Cancelling…'
                      ? null
                      : value.value.clamp(0, 1),
                  minHeight: 6.h,
                  backgroundColor: AppColors.grey200,
                ),
              ),
            ),
            if (showCancel) ...[
              SizedBox(width: 8.w),
              IconButton(
                tooltip: 'Cancel preparation',
                onPressed: onCancel,
                icon: Icon(Icons.close, size: 20.w),
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
        if (value.originalBytes != null || expectedBytes != null) ...[
          SizedBox(height: 12.h),
          if (value.originalBytes != null)
            _SizeMetric(
              label: 'Original',
              value: _formatBytes(value.originalBytes!),
            ),
          if (value.originalBytes != null && expectedBytes != null)
            SizedBox(height: 6.h),
          if (expectedBytes != null)
            _SizeMetric(
              label: value.label == 'Uploading video'
                  ? 'Compressed size'
                  : 'Expected size',
              value: _formatBytes(expectedBytes),
            ),
        ],
        if (expectedBytes != null && !withinLimit) ...[
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
  const _SizeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 11.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      SizedBox(width: 12.w),
      Text(
        value,
        style: AppTextStyles.interSemiBold16.copyWith(
          fontSize: 13.sp,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}
