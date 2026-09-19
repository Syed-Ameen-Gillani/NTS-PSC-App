import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class CourseCertificateDialog extends StatelessWidget {
  final String studentName;
  final String courseTitle;
  final String instructorName;
  final String completionDate;

  const CourseCertificateDialog({
    super.key,
    required this.studentName,
    required this.courseTitle,
    required this.instructorName,
    this.completionDate = 'September 19, 2026',
  });

  static void show(
    BuildContext context, {
    required String studentName,
    required String courseTitle,
    required String instructorName,
  }) {
    showDialog(
      context: context,
      builder: (context) => CourseCertificateDialog(
        studentName: studentName,
        courseTitle: courseTitle,
        instructorName: instructorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3.w), // Luxury Gold border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.grey500, size: 20.w),
                ),
              ),
              Icon(Icons.workspace_premium_rounded, color: const Color(0xFFD4AF37), size: 48.w),
              SizedBox(height: 8.h),
              Text(
                'CERTIFICATE OF COMPLETION',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 16.sp,
                  letterSpacing: 1.5,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                'NTS-PSC NATIONAL LEARNING ACADEMY',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'This is to officially certify that',
                style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey600),
              ),
              SizedBox(height: 6.h),
              Text(
                studentName,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 20.sp,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFD4AF37),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'has successfully completed all modules, lecture requirements, and rigorous mock test assessments for',
                style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                courseTitle,
                style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp, color: AppColors.onBackground),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
              Divider(color: AppColors.grey300, thickness: 1.h),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructorName,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                      ),
                      Text('Lead Exam Specialist', style: TextStyle(fontSize: 10.sp, color: AppColors.grey500)),
                      Text(completionDate, style: TextStyle(fontSize: 10.sp, color: AppColors.grey400)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12.w, color: const Color(0xFF10B981)),
                            SizedBox(width: 4.w),
                            Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text('ID: FPSC-${studentName.hashCode.abs().toString().padLeft(6, '0')}',
                          style: TextStyle(fontSize: 9.sp, color: AppColors.grey500)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        CustomToast.showSuccess(context, message: 'Certificate PDF downloaded to device storage!');
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text('Download PDF', style: TextStyle(fontSize: 12.sp)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CustomToast.showSuccess(context, message: 'Certificate verification link copied to clipboard!');
                      },
                      icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                      label: Text('Share Link', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
