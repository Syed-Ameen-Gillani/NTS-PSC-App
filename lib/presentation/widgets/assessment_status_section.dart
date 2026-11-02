import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AssessmentStatusSection extends StatelessWidget {
  static const previewLimit = 3;

  const AssessmentStatusSection({
    super.key,
    required this.title,
    required this.count,
    required this.children,
    this.onSeeAll,
  });

  final String title;
  final int count;
  final List<Widget> children;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 17.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '$count',
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 13.sp,
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (count > previewLimit && onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        SizedBox(height: 10.h),
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: 10.h),
          children[index],
        ],
      ],
    );
  }
}
