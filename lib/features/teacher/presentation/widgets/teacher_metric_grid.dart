import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class TeacherMetricItem {
  const TeacherMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
}

class TeacherMetricGrid extends StatelessWidget {
  const TeacherMetricGrid({super.key, required this.items});

  final List<TeacherMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600.w ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            mainAxisExtent: 132.h,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8.r),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 19.r,
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          item.icon,
                          color: AppColors.primary,
                          size: 19.w,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
