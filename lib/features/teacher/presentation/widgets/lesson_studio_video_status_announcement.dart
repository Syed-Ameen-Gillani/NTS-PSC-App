part of '../pages/teacher_lesson_media_screen.dart';

class _VideoStatusAnnouncement extends StatefulWidget {
  const _VideoStatusAnnouncement({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  @override
  State<_VideoStatusAnnouncement> createState() =>
      _VideoStatusAnnouncementState();
}

class _VideoStatusAnnouncementState extends State<_VideoStatusAnnouncement> {
  static const _displayDuration = Duration(milliseconds: 3500);
  static const _animationDuration = Duration(milliseconds: 280);

  final _visible = ValueNotifier<bool>(false);
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visible.value = true;
      _dismissTimer = Timer(_displayDuration, _dismiss);
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _visible.value = false;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _visible,
    builder: (context, visible, _) => AnimatedSwitcher(
      duration: _animationDuration,
      reverseDuration: _animationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.18),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? Container(
              key: ValueKey('video-status-visible-${widget.title}'),
              constraints: BoxConstraints(maxWidth: 350.w),
              padding: EdgeInsets.fromLTRB(12.w, 9.h, 6.w, 9.h),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: widget.color.withValues(alpha: 0.22),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, size: 18.w, color: widget.color),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 10.sp,
                            letterSpacing: 0.45,
                            color: widget.color,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.message,
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 11.sp,
                            height: 1.3,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),
                  SizedBox.square(
                    dimension: 28.w,
                    child: IconButton(
                      tooltip: 'Dismiss video status',
                      padding: EdgeInsets.zero,
                      onPressed: _dismiss,
                      icon: Icon(Icons.close_rounded, size: 17.w),
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('video-status-hidden')),
    ),
  );
}
