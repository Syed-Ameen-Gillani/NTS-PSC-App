import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import '../controllers/learning_outcome_provider.dart';
export '../controllers/learning_outcome_provider.dart';

const _announcementDuration = Duration(milliseconds: 3500);
const _animationDuration = Duration(milliseconds: 280);

class _CompletionAnnouncement {
  const _CompletionAnnouncement({
    this.visible = false,
    this.pending = false,
    this.completed,
  });

  final bool visible;
  final bool pending;
  final bool? completed;
}

class _CompletionAnnouncementController
    extends StateNotifier<_CompletionAnnouncement> {
  _CompletionAnnouncementController() : super(const _CompletionAnnouncement());

  bool? _lastCompleted;
  Timer? _dismissTimer;

  void observe(bool completed, {required bool canDisplay}) {
    if (_lastCompleted == null) {
      _lastCompleted = completed;
      return;
    }
    if (_lastCompleted == completed) return;
    _lastCompleted = completed;
    _dismissTimer?.cancel();
    if (canDisplay) {
      _show(completed);
    } else {
      state = _CompletionAnnouncement(pending: true, completed: completed);
    }
  }

  void revealPending() {
    if (!state.pending || state.completed == null) return;
    _show(state.completed!);
  }

  void _show(bool completed) {
    state = _CompletionAnnouncement(visible: true, completed: completed);
    _dismissTimer = Timer(_announcementDuration, dismiss);
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (state.visible) {
      state = _CompletionAnnouncement(completed: state.completed);
    } else if (state.pending) {
      state = _CompletionAnnouncement(completed: state.completed);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}

final _completionAnnouncementProvider = StateNotifierProvider.autoDispose
    .family<_CompletionAnnouncementController, _CompletionAnnouncement, String>(
      (ref, lessonId) => _CompletionAnnouncementController(),
    );

/// Announces genuine server-confirmed lesson completion changes.
///
/// The first observed status is a silent baseline. A banner is shown only when
/// that status later changes, preventing ordinary rebuilds and navigation from
/// repeatedly announcing the same state.
class AutomaticLearningStatus extends ConsumerWidget {
  const AutomaticLearningStatus({
    super.key,
    required this.lessonId,
    this.previewRequiredCount,
  });

  final String lessonId;
  final int? previewRequiredCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      _completionAnnouncementProvider(lessonId).notifier,
    );
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    ref.listen(learningOutcomeProvider(lessonId), (_, next) {
      next.whenData(
        (data) => controller.observe(
          data['completed'] == true,
          canDisplay: isCurrentRoute,
        ),
      );
    });
    final announcement = ref.watch(_completionAnnouncementProvider(lessonId));
    if (isCurrentRoute && announcement.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.revealPending();
      });
    }
    final visible = previewRequiredCount == null && announcement.visible;

    return AnimatedSwitcher(
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
          ? Padding(
              key: ValueKey('completion-${announcement.completed}'),
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBanner(
                  completed: announcement.completed == true,
                  onDismiss: controller.dismiss,
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('completion-hidden')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.completed, required this.onDismiss});

  final bool completed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('lesson-completion-banner'),
    constraints: BoxConstraints(maxWidth: 350.w),
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 6.w, 10.h),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      border: Border(
        bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          completed
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 20.w,
          color: AppColors.primary,
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                completed ? 'LESSON COMPLETED' : 'LESSON INCOMPLETE',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                completed
                    ? 'All required activities have been completed.'
                    : 'Complete the required activities to continue.',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 11.sp,
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
            key: const ValueKey('dismiss-completion-banner'),
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 17.w),
            color: AppColors.grey600,
          ),
        ),
      ],
    ),
  );
}
