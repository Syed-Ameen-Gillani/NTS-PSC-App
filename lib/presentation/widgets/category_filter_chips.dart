import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CategoryFilterChips extends StatefulWidget {
  final List<String> filters;
  final int initialSelectedIndex;
  final ValueChanged<int>? onSelected;

  const CategoryFilterChips({
    super.key,
    this.filters = const ['All', 'AJK PSC', 'FPSC', 'NTS', 'CSS'],
    this.initialSelectedIndex = 0,
    this.onSelected,
  });

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: widget.filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              if (widget.onSelected != null) {
                widget.onSelected!(index);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFDADCE0),
                  width: 1.w,
                ),
              ),
              child: Text(
                widget.filters[index],
                style: AppTextStyles.interMedium16.copyWith(
                  color: isSelected ? Colors.white : AppColors.onBackground,
                  fontSize: 14.sp,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
