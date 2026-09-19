import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';

class PopularTeachersList extends StatelessWidget {
  final List<TeacherModel> teachers;

  const PopularTeachersList({super.key, required this.teachers});

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Popular Teachers',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 148.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            scrollDirection: Axis.horizontal,
            itemCount: teachers.length,
            separatorBuilder: (context, index) => SizedBox(width: 20.w),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return InkWell(
                onTap: () {
                  context.pushNamed(AppRoute.publicTeacherProfile.name, extra: teacher);
                },
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  width: 84.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74.w,
                        height: 74.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x331A73E8),
                            width: 2.w,
                          ),
                          image: DecorationImage(
                            image: AssetImage(teacher.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        teacher.name,
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.onBackground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        teacher.subject,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.grey500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
