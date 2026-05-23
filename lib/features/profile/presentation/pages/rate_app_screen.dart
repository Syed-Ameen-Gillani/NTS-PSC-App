import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _submitted
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.onBackground,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
        title: Text(
          'Rate the App',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: _submitted ? 24.w : 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _submitted ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 32.h),
          Icon(Icons.favorite, color: const Color(0xFFEF4444), size: 64.w),
          SizedBox(height: 32.h),
          Text(
            'Enjoying LMS App?',
            style: AppTextStyles.interBold30.copyWith(
              fontSize: 24.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Your feedback helps us improve and provide a better learning experience for everyone.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular16.copyWith(
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          SizedBox(height: 48.h),

          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: index < _rating
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                    size: 40.w,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 48.h),

          // Feedback Field
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tell us more (optional)',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 14.sp,
                color: AppColors.onBackground,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'What do you love? What could we do better?',
              hintStyle: AppTextStyles.interRegular14.copyWith(
                color: AppColors.grey400,
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: EdgeInsets.all(16.w),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1.w,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5.w),
              ),
            ),
          ),

          SizedBox(height: 48.h),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () {
                if (_rating == 0) {
                  CustomToast.showError(
                    context,
                    message: 'Please select at least one star to continue.',
                  );
                  return;
                }
                setState(() {
                  _submitted = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit Review',
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Maybe Later
          // TextButton(
          //   onPressed: () => context.pop(),
          //   child: Text(
          //     'Maybe Later',
          //     style: AppTextStyles.interSemiBold16.copyWith(
          //       color: AppColors.grey500,
          //       fontSize: 16.sp,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Success Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F4EA), // Very light green
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), // Emerald green
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 32.w),
            ),
          ),
          SizedBox(height: 32.h),

          // Title
          Text(
            'Thank You!',
            style: AppTextStyles.interBold30.copyWith(
              fontSize: 28.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 16.h),

          // Subtitle
          Text(
            'Your feedback has been successfully submitted. We appreciate you taking the time to help us improve the LMS App for everyone.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular16.copyWith(
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),

          const Spacer(),

          // Back to Profile Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () {
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Back to Profile',
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
