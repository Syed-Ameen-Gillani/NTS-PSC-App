// lib/features/home/presentation/pages/home_screen.dart
// HomeScreen UI - Pixel-accurate reproduction of the Educora home screen design
// Date: 2025-12-03
// Screenshot reference: Educora Home Screen (Mobile)
// Recommended preview device: Pixel 5 (412x915) or similar

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

/// Main HomeScreen widget - UI only, no business logic
///
/// To test in isolation:
/// ```dart
/// void main() => runApp(MaterialApp(home: HomeScreen()));
/// ```
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Design constants
  static const Color kPrimaryBlue = Color(0xFF3787FF);
  static const Color kBackgroundColor = Color(0xFFF8F9FA);
  static const Color kTextPrimary = Color(0xFF1A1A1A);
  static const Color kTextHeading = Color(0xFF060302);

  static const Color kTextSecondary = Color(0xFF767372);
  static const Color kOrangeAccent = Color(0xFFFF9D42);
  static const Color kStarYellow = Color(0xFFFFA500);

  static const double kHorizontalPadding = 20;
  static const double kVerticalSpacing = 20.0;
  static const double kCardRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F1F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and avatar
              SizedBox(height: 40.h),
              _buildHeader(),
              SizedBox(height: 36.h),

              // Search bar
              _buildSearchBar(),
              SizedBox(height: 40.h),

              // Popular category section
              _buildPopularCategory(),
              SizedBox(height: 40.h),

              // Most watching category
              _buildMostWatchingCategory(),
              SizedBox(height: 40.h),

              // Popular teachers
              _buildPopularTeachers(),
              SizedBox(height: 40.h),

              // Trial banner
              Align(
                child: _buildTrialBanner(),
                alignment: AlignmentGeometry.center,
              ),
              SizedBox(height: 40.h),

              // Continue watching
              _buildContinueWatching(),
              SizedBox(height: 40.h),

              // What others are watching
              _buildWhatOthersWatching(),
              SizedBox(height: 80.h), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kHorizontalPadding.w,
        // vertical: 12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, Ayesha!',
                style: AppTextStyles.dmSans600med24.copyWith(
                  fontSize: 20.sp,
                  color: kTextHeading,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                'What do you Want to learn Today?',
                style: AppTextStyles.dmSans500med24.copyWith(
                  fontSize: 12.sp,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          // User avatar - replace with actual image
          Container(
            height: 44.h,
            width: 44.w,
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.6),
              borderRadius: BorderRadius.circular(50.r),
            ),

            child: Icon(Icons.person, color: Colors.white, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            SizedBox(width: 20.w),
            Text(
              'Mathematics Lecturer Test Prepln',
              style: TextStyle(
                fontSize: 14.sp,
                color: kTextSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: SvgPicture.asset(
                AppAssets.searchIcon,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCategory() {
    return Column(
      children: [
        _buildSectionHeader('Popular category\nour in platform', 'see more'),
        SizedBox(height: 36.h),
        SizedBox(
          height: 120.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            children: [
              _buildCategoryCard('Algebra', Colors.grey[200]!),
              SizedBox(width: 16.w),
              _buildCategoryCard('Trigonometry', const Color(0xFFFF6B6B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, Color bgColor) {
    return Container(
      width: 160.w,
      height: 140.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.course1, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0001),
                  Colors.black.withOpacity(0.0157),
                  Colors.black.withOpacity(0.0549),
                  Colors.black.withOpacity(0.1176),
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.2902),
                  Colors.black.withOpacity(0.3922),
                  Colors.black.withOpacity(0.502),
                  Colors.black.withOpacity(0.6078),
                  Colors.black.withOpacity(0.7098),
                  Colors.black.withOpacity(0.80),
                  Colors.black.withOpacity(0.8824),
                  Colors.black.withOpacity(0.9451),
                  Colors.black.withOpacity(0.9843),
                  Colors.black,
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 12.h,
            left: 12.w,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostWatchingCategory() {
    return Column(
      children: [
        _buildSectionHeader('Most watching\ncategory in month', 'see more'),
        SizedBox(height: 36.h),
        SizedBox(
          height: 239.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            children: [
              _buildCourseCard('Trigonometry', '(891)', 4.5, kOrangeAccent),
              SizedBox(width: 16.w),
              _buildCourseCard(
                'Statistics',
                '(456)',
                4.2,
                const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(
    String title,
    String reviews,
    double rating,
    Color accentColor,
  ) {
    return Container(
      width: 160.w,
      // height: 239.h,
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius.r),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image placeholder
          Container(
            height: 143.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Image.asset(AppAssets.course1, fit: BoxFit.cover),
            // Replace with: Image.asset('assets/images/course_$title.jpg', fit: BoxFit.cover)
          ),
          SizedBox(height: 15.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,

                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Sayef Mamud, PixelCo",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.dmSans500med12.copyWith(
                  color: kPrimaryBlue,
                ),
              ),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Text(
                      rating.toString(),

                      style: TextStyle(fontSize: 10.sp, color: kPrimaryBlue),
                    ),
                    SizedBox(width: 6.w),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        color: kStarYellow,
                        size: 14.sp,
                      );
                    }),

                    SizedBox(width: 6.w),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        reviews,
                        style: TextStyle(fontSize: 10.sp, color: kPrimaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTeachers() {
    return Column(
      children: [
        _buildSectionHeader('Our top popular\nteacher this month', ''),
        SizedBox(height: 36.h),
        SizedBox(
          height: 232.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            children: [
              _buildTeacherCard('Dr Fasial', 'Teacher', Colors.yellow[700]!),
              SizedBox(width: 16.w),
              _buildTeacherCard(
                'Dr Ayesha',
                'Creative artist',
                Colors.pink[300]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard(String name, String title, Color bgColor) {
    return Container(
      width: 173.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher photo with background
          SizedBox(
            height: 154.h,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(kCardRadius.r),
                    ),
                  ),
                ),
                Positioned(
                  top: 47.h,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(kCardRadius.r),
                    ),
                    child: Image.asset(AppAssets.teacherBg, fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(kCardRadius.r),
                    ),
                    child: Image.asset(
                      AppAssets.teacher1,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: TextStyle(fontSize: 12.sp, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
      child: Container(
        width: double.infinity,
        height: 160.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              'Try free trail to increase\nyour creative journey!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            // SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {}, // Placeholder - no navigation
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Get free trial',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatching() {
    return Column(
      children: [
        _buildSectionHeader('Continue to watch\nprevious class', 'see more'),
        SizedBox(height: 24.h),
        SizedBox(
          height: 239.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            children: [
              _buildCourseCard(
                'Educational Psychology',
                '(456)',
                4.0,
                kOrangeAccent,
              ),
              SizedBox(width: 16.w),
              _buildCourseCard(
                'Curriculum Development',
                '(789)',
                4.5,
                const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatOthersWatching() {
    return Column(
      children: [
        _buildSectionHeader('What others are\nwatching in app', 'see more'),
        SizedBox(height: 24.h),
        SizedBox(
          height: 239.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
            children: [
              _buildCourseCard('Time Management', '(234)', 4.3, kOrangeAccent),
              SizedBox(width: 16.w),
              _buildCourseCard(
                'How to do NTS Exam',
                '(567)',
                4.7,
                const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans600med24.copyWith(
              color: kTextPrimary,
              fontSize: 20.sp,
              height: 1.3,
            ),
          ),
          if (action.isNotEmpty)
            Text(
              action,
              style: AppTextStyles.dmSans600med24.copyWith(
                fontSize: 14.sp,

                color: kPrimaryBlue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.search, 'Search', false),
          _buildNavItem(Icons.bookmark_border, 'Saved', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? kPrimaryBlue : kTextSecondary,
          size: 24.sp,
        ),
        if (isActive)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            height: 3.h,
            width: 3.w,
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
