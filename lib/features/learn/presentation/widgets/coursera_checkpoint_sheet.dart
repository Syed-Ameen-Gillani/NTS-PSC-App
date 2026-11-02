part of 'hosted_lesson_player.dart';

final _checkpointSelected = StateProvider.autoDispose.family<int?, Object>(
  (ref, key) => null,
);
final _checkpointEvaluating = StateProvider.autoDispose.family<bool, Object>(
  (ref, key) => false,
);
final _checkpointResult = StateProvider.autoDispose
    .family<Map<String, dynamic>?, Object>((ref, key) => null);

enum _CheckpointAction { continueVideo, rewind, dismiss }

class _CourseraCheckpointSheet extends ConsumerStatefulWidget {
  const _CourseraCheckpointSheet({
    required this.question,
    required this.options,
    required this.timestampDisplay,
    required this.onSubmit,
  });

  final String question;
  final List<String> options;
  final String timestampDisplay;
  final Future<Map<String, dynamic>?> Function(int selectedOption) onSubmit;

  @override
  ConsumerState<_CourseraCheckpointSheet> createState() =>
      _CourseraCheckpointSheetState();
}

class _CourseraCheckpointSheetState
    extends ConsumerState<_CourseraCheckpointSheet> {
  final _identity = Object();
  int? get _selectedOption => ref.read(_checkpointSelected(_identity));
  bool get _isEvaluating => ref.read(_checkpointEvaluating(_identity));
  Map<String, dynamic>? get _result => ref.read(_checkpointResult(_identity));

  Future<void> _handleCheck() async {
    if (_selectedOption == null || _isEvaluating) return;
    ref.read(_checkpointEvaluating(_identity).notifier).state = true;
    try {
      final res = await widget.onSubmit(_selectedOption!);
      if (mounted) {
        ref.read(_checkpointResult(_identity).notifier).state =
            res ?? {'queued': true};
      }
    } finally {
      if (mounted) {
        ref.read(_checkpointEvaluating(_identity).notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_checkpointSelected(_identity));
    ref.watch(_checkpointEvaluating(_identity));
    ref.watch(_checkpointResult(_identity));
    final hasResult = _result != null;
    final isCorrect = _result?['isCorrect'] == true;
    final isQueued = _result?['queued'] == true;
    final error = _result?['error'] as String?;
    final explanation =
        _result?['explanation'] as String? ??
        (isCorrect
            ? 'Great job! You have grasped the key concept of this section.'
            : 'Review this concept to master the material.');

    return Container(
      margin: EdgeInsets.only(top: 80.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14.w,
                          color: const Color(0xFFE65100),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'KNOWLEDGE CHECKPOINT • ${widget.timestampDisplay}',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 11.sp,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.grey500),
                    onPressed: () =>
                        Navigator.of(context).pop(_CheckpointAction.dismiss),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Question
              Text(
                widget.question,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 15.sp,
                  height: 1.4,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16.h),

              // Options
              ...List.generate(widget.options.length, (index) {
                final optionText = widget.options[index];
                final isSelected = _selectedOption == index;
                final letter = String.fromCharCode(65 + index);

                Color borderColor = AppColors.grey300;
                Color bgColor = Colors.white;

                if (hasResult) {
                  if (isSelected) {
                    if (isCorrect) {
                      borderColor = Colors.green.shade600;
                      bgColor = const Color(0xFFE8F5E9);
                    } else if (error != null) {
                      borderColor = AppColors.grey400;
                      bgColor = AppColors.grey100;
                    } else {
                      borderColor = Colors.red.shade400;
                      bgColor = const Color(0xFFFFEBEE);
                    }
                  }
                } else if (isSelected) {
                  borderColor = AppColors.primary;
                  bgColor = const Color(0xFFEFF6FF);
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    onTap: (hasResult && isCorrect) || _isEvaluating
                        ? null
                        : () =>
                              ref
                                      .read(
                                        _checkpointSelected(_identity).notifier,
                                      )
                                      .state =
                                  index,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12.r,
                            backgroundColor: isSelected
                                ? (isCorrect
                                      ? Colors.green.shade600
                                      : (!isCorrect &&
                                                hasResult &&
                                                error == null
                                            ? Colors.red.shade400
                                            : AppColors.primary))
                                : AppColors.grey200,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.grey700,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 13.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Result Banner
              if (hasResult) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFE8F5E9)
                        : (isQueued
                              ? const Color(0xFFE0F2FE)
                              : (error != null
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFFF3E0))),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade400
                          : (isQueued
                                ? const Color(0xFF38BDF8)
                                : (error != null
                                      ? Colors.red.shade300
                                      : Colors.orange.shade400)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : (isQueued
                                      ? Icons.cloud_upload_outlined
                                      : (error != null
                                            ? Icons.error_outline
                                            : Icons.info_outline)),
                            color: isCorrect
                                ? Colors.green.shade700
                                : (isQueued
                                      ? const Color(0xFF0284C7)
                                      : (error != null
                                            ? Colors.red.shade700
                                            : Colors.orange.shade800)),
                            size: 18.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            isCorrect
                                ? 'Correct! Well done.'
                                : (isQueued
                                      ? 'Saved for Sync'
                                      : (error != null
                                            ? 'Notice'
                                            : 'Not quite right')),
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 13.sp,
                              color: isCorrect
                                  ? Colors.green.shade800
                                  : (isQueued
                                        ? const Color(0xFF0369A1)
                                        : (error != null
                                              ? Colors.red.shade900
                                              : Colors.orange.shade900)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        error ??
                            (isQueued
                                ? 'Your answer was queued and will sync when online.'
                                : explanation),
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          height: 1.4,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 18.h),

              // Actions
              if (!hasResult) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedOption == null || _isEvaluating
                        ? null
                        : _handleCheck,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isEvaluating
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Check Answer',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ] else if (isCorrect || isQueued || error != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_CheckpointAction.continueVideo),
                    style: FilledButton.styleFrom(
                      backgroundColor: isCorrect
                          ? Colors.green.shade600
                          : AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Continue Video ▶',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay_10, size: 16),
                        label: Text(
                          'Rewind 15s to Review',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        onPressed: () =>
                            Navigator.of(context).pop(_CheckpointAction.rewind),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ref
                                  .read(_checkpointResult(_identity).notifier)
                                  .state =
                              null;
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
