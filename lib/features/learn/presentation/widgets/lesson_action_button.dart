import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class LessonActionButton extends StatefulWidget {
  const LessonActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.onBackground,
    this.disabledColor = AppColors.grey400,
    this.localizeFeedbackToIcon = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color disabledColor;
  final bool localizeFeedbackToIcon;

  @override
  State<LessonActionButton> createState() => _LessonActionButtonState();
}

class _LessonActionButtonState extends State<LessonActionButton> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.onTap == null
        ? widget.disabledColor
        : widget.color;
    final localized = widget.localizeFeedbackToIcon;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: localized ? Colors.transparent : null,
        highlightColor: localized ? Colors.transparent : null,
        onHighlightChanged: localized
            ? (highlighted) {
                if (_highlighted != highlighted) {
                  setState(() => _highlighted = highlighted);
                }
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 68.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: localized ? 32.w : null,
                height: localized ? 32.w : null,
                alignment: Alignment.center,
                decoration: localized
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        color: _highlighted
                            ? widget.color.withValues(alpha: 0.12)
                            : Colors.transparent,
                      )
                    : null,
                child: IconTheme(
                  data: IconThemeData(color: effectiveColor, size: 21.w),
                  child: widget.icon,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
