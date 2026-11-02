import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/course_pricing.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

final paidCourseDraftProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);

class CoursePricingField extends ConsumerWidget {
  const CoursePricingField({
    super.key,
    required this.draftId,
    required this.controller,
  });
  final String draftId;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paid = ref.watch(paidCourseDraftProvider(draftId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 14.h, bottom: 8.h),
          child: Text(
            'Course type',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 13.sp,
              color: AppColors.onBackground,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _CourseTypeOption(
                icon: Icons.school_outlined,
                label: 'Free',
                selected: !paid,
                onTap: () =>
                    ref.read(paidCourseDraftProvider(draftId).notifier).state =
                        false,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _CourseTypeOption(
                icon: Icons.sell_outlined,
                label: 'Paid',
                selected: paid,
                onTap: () =>
                    ref.read(paidCourseDraftProvider(draftId).notifier).state =
                        true,
              ),
            ),
          ],
        ),
        if (paid) ...[
          SizedBox(height: 12.h),
          CustomTextFormField(
            controller: controller,
            hintText: 'Price in PKR',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                CoursePricing.parsePaidAmount(value ?? '') == null
                ? 'Enter 1 to 1,000,000 PKR in whole rupees'
                : null,
          ),
          SizedBox(height: 6.h),
          Text(
            'Paid enrollment will be available after payment setup.',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }
}

class _CourseTypeOption extends StatelessWidget {
  const _CourseTypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.grey700;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label course',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : AppColors.settingsCardBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.settingsCardBorder,
                width: selected ? 1.5.w : 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18.w, color: foreground),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 14.sp,
                    color: foreground,
                  ),
                ),
                if (selected) ...[
                  SizedBox(width: 6.w),
                  Icon(Icons.check_circle, size: 16.w, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
