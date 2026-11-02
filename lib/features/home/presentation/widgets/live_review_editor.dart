import '../controllers/review_submission_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';

import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final _rating = StateProvider.autoDispose.family<int, Object>((ref, key) => 0);

class LiveReviewEditor extends ConsumerStatefulWidget {
  const LiveReviewEditor({super.key, required this.courseId, this.review});
  final String courseId;
  final Map<String, dynamic>? review;
  @override
  ConsumerState<LiveReviewEditor> createState() => _LiveReviewEditorState();
}

class _LiveReviewEditorState extends ConsumerState<LiveReviewEditor> {
  final identity = Object();
  final form = GlobalKey<FormState>();
  late final TextEditingController body;
  String? owner;
  @override
  void initState() {
    super.initState();
    body = TextEditingController(text: widget.review?['body'] as String? ?? '');
    owner = ref.read(authControllerProvider).value?.user?.id;
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (owner == null ||
        ref.read(authControllerProvider).value?.user?.id != owner) {
      CustomToast.showError(
        context,
        message: 'Reopen reviews after signing in.',
      );
      return;
    }
    if (ref.read(reviewSubmissionProvider(widget.courseId))) return;
    if (!(form.currentState?.validate() ?? false)) return;
    final selected = ref.read(_rating(identity));
    final rating = selected == 0
        ? (widget.review?['rating'] as num?)?.toInt() ?? 0
        : selected;
    if (rating == 0) {
      CustomToast.showError(context, message: 'Choose a rating first.');
      return;
    }
    try {
      await ref
          .read(reviewSubmissionProvider(widget.courseId).notifier)
          .save(rating, body.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      CustomToast.showSuccess(context, message: 'Your review has been saved.');
    } catch (_) {
      if (mounted) {
        CustomToast.showError(
          context,
          message: 'Could not save your review. Please retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(
      authControllerProvider.select((value) => value.value?.user?.id),
    );
    if (account != owner || account == null) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: const Text('Reopen reviews after signing in.'),
        ),
      );
    }
    final saving = ref.watch(reviewSubmissionProvider(widget.courseId));
    final selected = ref.watch(_rating(identity));
    final rating = selected == 0
        ? (widget.review?['rating'] as num?)?.toInt() ?? 0
        : selected;
    return PopScope(
      canPop: !saving,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: saving,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                MediaQuery.viewInsetsOf(context).bottom + 20.h,
              ),
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.review == null
                                ? 'Write a review'
                                : 'Edit your review',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 20.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Your feedback helps other students choose with confidence.',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.grey500,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Center(
                      child: Text(
                        _ratingLabel(rating),
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Center(
                      child: Wrap(
                        children: [
                          for (var star = 1; star <= 5; star++)
                            IconButton(
                              tooltip: '$star stars',
                              onPressed: () =>
                                  ref.read(_rating(identity).notifier).state =
                                      star,
                              icon: Icon(
                                star <= rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: star <= rating
                                    ? AppColors.accent
                                    : AppColors.grey300,
                                size: 32.w,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Your review',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: body,
                      maxLength: 2000,
                      minLines: 4,
                      maxLines: 6,
                      onTapOutside: dismissKeyboardOnTapOutside,
                      decoration: InputDecoration(
                        hintText: 'What did you find useful about this course?',
                        hintStyle: AppTextStyles.interRegular14.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.grey400,
                        ),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: AppColors.settingsCardBackground,
                        contentPadding: EdgeInsets.all(14.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.settingsCardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.settingsCardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Write at least 3 characters.'
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: FilledButton(
                        onPressed: saving ? null : save,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: saving
                            ? SizedBox.square(
                                dimension: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) => switch (rating) {
    1 => 'Poor',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Very good',
    5 => 'Excellent',
    _ => 'Choose a rating',
  };
}
