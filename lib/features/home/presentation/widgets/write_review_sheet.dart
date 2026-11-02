import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class WriteReviewSheet extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const WriteReviewSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  static Future<void> show(BuildContext context, {required String courseId, required String courseTitle}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewSheet(courseId: courseId, courseTitle: courseTitle),
    );
  }

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      CustomToast.showError(context, message: 'Please share a few words about your learning experience');
      return;
    }

    final authUser = ref.read(authControllerProvider).value?.user;
    final studentName = authUser?.name ?? 'Enrolled Student';

    ref.read(courseCommunityProvider.notifier).submitReview(
      courseId: widget.courseId,
      studentName: studentName,
      rating: _selectedRating.toDouble(),
      comment: comment,
    );

    Navigator.pop(context);
    CustomToast.showSuccess(context, message: 'Thank you! Your verified review has been posted.');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Rate & Review Course',
              style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp, color: AppColors.onBackground),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.courseTitle,
              style: AppTextStyles.interRegular14.copyWith(fontSize: 13.sp, color: AppColors.grey500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20.h),
            Center(
              child: Text(
                'How was your experience?',
                style: AppTextStyles.interSemiBold16.copyWith(fontSize: 15.sp, color: AppColors.onBackground),
              ),
            ),
            SizedBox(height: 12.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 36.w,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    onPressed: () => setState(() => _selectedRating = starNum),
                    icon: Icon(
                      starNum <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Your Detailed Feedback',
              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp, color: AppColors.onBackground),
            ),
            SizedBox(height: 8.h),
            TextField(
              onTapOutside: dismissKeyboardOnTapOutside,
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share what helped you the most (e.g. past paper questions, video explanations, syllabus depth)...',
                hintStyle: AppTextStyles.interRegular14.copyWith(color: AppColors.grey400, fontSize: 13.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.grey300, width: 1.w),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5.w),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                child: Text(
                  'Submit Verified Review',
                  style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 15.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
