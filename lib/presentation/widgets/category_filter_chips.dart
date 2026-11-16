import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_gradients.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CategoryFilterChips extends StatefulWidget {
  final List<String> filters;
  final int initialSelectedIndex;
  final ValueChanged<int>? onSelected;
  final bool includeHorizontalPadding;
  final bool wrap;

  const CategoryFilterChips({
    super.key,
    this.filters = const ['All', 'AJK PSC', 'FPSC', 'NTS', 'CSS'],
    this.initialSelectedIndex = 0,
    this.onSelected,
    this.includeHorizontalPadding = true,
    this.wrap = false,
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
  void didUpdateWidget(CategoryFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedIndex != widget.initialSelectedIndex ||
        !listEquals(oldWidget.filters, widget.filters)) {
      _selectedIndex = widget.initialSelectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(int index) {
      final isSelected = _selectedIndex == index;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
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
          alignment: widget.wrap ? null : Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? null : const Color(0xFFF8F9FA),
            gradient: isSelected
                ? AppGradients.primaryBanner(Theme.of(context).colorScheme)
                : null,
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFDADCE0),
              width: 1.w,
            ),
          ),
          child: Text(
            widget.filters[index],
            style: AppTextStyles.interMedium16.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.onBackground,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    if (widget.wrap) {
      return Padding(
        padding: widget.includeHorizontalPadding
            ? EdgeInsets.symmetric(horizontal: 24.w)
            : EdgeInsets.zero,
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (var index = 0; index < widget.filters.length; index++)
              chip(index),
          ],
        ),
      );
    }
    // Height scaling and font scaling can differ on short screens. Reserve the
    // actual line height, scaled text and existing padding before constraining
    // the horizontal viewport so it cannot clip the labels.
    var labelStyle = DefaultTextStyle.of(
      context,
    ).style.merge(AppTextStyles.interMedium16.copyWith(fontSize: 14.sp));
    if (MediaQuery.boldTextOf(context)) {
      labelStyle = labelStyle.copyWith(fontWeight: FontWeight.bold);
    }
    final painter = TextPainter(
      text: TextSpan(text: widget.filters.join(' '), style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final height = math.max(36.h, painter.height + 16.h + 2.w).ceilToDouble();
    painter.dispose();
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: widget.includeHorizontalPadding
            ? EdgeInsets.symmetric(horizontal: 24.w)
            : EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: widget.filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, index) => chip(index),
      ),
    );
  }
}
