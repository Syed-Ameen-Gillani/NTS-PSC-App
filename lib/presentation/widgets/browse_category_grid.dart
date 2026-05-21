import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class BrowseCategoryGrid extends StatelessWidget {
  final String title;
  final String actionText;
  final List<CategoryModel> categories;

  const BrowseCategoryGrid({
    super.key,
    required this.title,
    required this.actionText,
    required this.categories,
  });

  IconData _getIcon(String iconType) {
    switch (iconType) {
      case 'document':
        return Icons.description_outlined;
      case 'globe':
        return Icons.public_outlined;
      case 'clipboard':
        return Icons.assignment_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.onBackground,
                  height: 1.2,
                ),
              ),
              Text(
                actionText,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w), // Figma left: 16px
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.w, // gap: 8px
              crossAxisSpacing: 8.w, // gap: 8px
              childAspectRatio: 163.5 / 126, // width / height
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                padding: EdgeInsets.all(16.w), // padding: 16px
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA), // bg: #F8F9FA
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFDADCE0), width: 1.w), // border color
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        _getIcon(category.iconType),
                        color: AppColors.primary,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      category.name,
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${category.courseCount} courses',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
