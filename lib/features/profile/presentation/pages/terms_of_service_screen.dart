import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Terms of Service',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 24.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Last updated: October 15, 2024',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 24.h),
              _buildParagraph('Please read these terms and conditions carefully before using Our Service. By accessing or using the Service, You agree to be bound by these Terms. If You disagree with any part of these Terms then You may not access the Service.'),
              
              _buildSectionTitle('1. Account Registration'),
              _buildParagraph('When You create an account with Us, You must provide us information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account on Our Service.'),
              _buildParagraph('You are responsible for safeguarding the password that You use to access the Service and for any activities or actions under Your password.'),
              
              _buildSectionTitle('2. Course Content and Intellectual Property'),
              _buildParagraph('The Service and its original content, features and functionality are and will remain the exclusive property of LMS App and its licensors. The Service is protected by copyright, trademark, and other laws of both the Country and foreign countries.'),
              _buildParagraph('You may not modify, reproduce, distribute, create derivative works or adapt in any way exploit any of the materials available on the Service in whole or in part except as expressly authorized by Us.'),
              
              _buildSectionTitle('3. Subscriptions and Payments'),
              _buildParagraph('Some parts of the Service are billed on a subscription basis. You will be billed in advance on a recurring and periodic basis. At the end of each period, Your Subscription will automatically renew under the exact same conditions unless You cancel it or We cancel it.'),
              _buildParagraph('A valid payment method, including credit card, is required to process the payment for Your Subscription. You shall provide Us with accurate and complete billing information.'),
              
              _buildSectionTitle('4. Termination'),
              _buildParagraph('We may terminate or suspend Your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms of Service. Upon termination, Your right to use the Service will cease immediately.'),
              
              _buildSectionTitle('5. Changes to these Terms'),
              _buildParagraph('We reserve the right, at Our sole discretion, to modify or replace these Terms at any time. If a revision is material We will make reasonable efforts to provide at least 30 days\' notice prior to any new terms taking effect. What constitutes a material change will be determined at Our sole discretion.'),
              
              SizedBox(height: 32.h),
              _buildContactCard(),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
      child: Text(
        title,
        style: AppTextStyles.interBold24.copyWith(
          fontSize: 16.sp,
          color: AppColors.onBackground,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        text,
        style: AppTextStyles.interRegular16.copyWith(
          fontSize: 14.sp,
          color: AppColors.grey500,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 16.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'If you have any questions about these Terms, please contact us.',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 14.sp,
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2), // Match screenshot
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Email Support',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
