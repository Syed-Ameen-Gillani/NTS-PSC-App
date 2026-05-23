import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                'Privacy Policy',
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
              _buildParagraph('This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You. We use Your Personal data to provide and improve the Service.'),
              
              _buildSectionTitle('1. Information We Collect'),
              _buildParagraph('While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to: Email address, First name and last name, Phone number, and Usage Data.'),
              _buildParagraph('Usage Data is collected automatically when using the Service. It may include information such as Your Device\'s Internet Protocol address, browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, and other diagnostic data.'),
              
              _buildSectionTitle('2. How We Use Your Data'),
              _buildParagraph('We may use Personal Data for the following purposes: to provide and maintain our Service, to manage Your Account, for the performance of a contract, to contact You, to provide You with news and special offers, to manage Your requests, and for business transfers.'),
              
              _buildSectionTitle('3. Sharing Your Information'),
              _buildParagraph('We may share Your personal information in the following situations: With Service Providers to monitor and analyze the use of our Service, for business transfers, with Affiliates, with business partners, and with other users if you share personal information in public areas.'),
              
              _buildSectionTitle('4. Security of Your Data'),
              _buildParagraph('The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While We strive to use commercially acceptable means to protect Your Personal Data, We cannot guarantee its absolute security.'),
              
              _buildSectionTitle('5. Children\'s Privacy'),
              _buildParagraph('Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us.'),
              
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
            'If you have any questions or concerns about this Privacy Policy, please contact our data protection officer.',
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
              'Email Privacy Team',
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
