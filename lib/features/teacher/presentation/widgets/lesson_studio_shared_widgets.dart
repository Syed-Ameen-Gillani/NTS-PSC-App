part of '../pages/teacher_lesson_media_screen.dart';

extension _LessonStudioSharedWidgets on _TeacherLessonMediaScreenState {
  Widget _buildAttachedHeader({
    required String title,
    VoidCallback? onRetry,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 12.sp,
            color: AppColors.grey500,
            letterSpacing: 0.8,
          ),
        ),
        trailing ??
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh,
                size: 20,
                color: AppColors.primary,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRetry,
            ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 1: VIDEO
  // -------------------------------------------------------------
  Widget _compactAddAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final iconWidget = Icon(icon, size: 18.w);
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
    );
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: labelWidget,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          shape: shape,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: labelWidget,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        side: const BorderSide(color: AppColors.grey300),
        shape: shape,
      ),
    );
  }
}

class _AttachedEmptyState extends StatelessWidget {
  const _AttachedEmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20.w, color: AppColors.grey500),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: AppTextStyles.interMedium16.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
