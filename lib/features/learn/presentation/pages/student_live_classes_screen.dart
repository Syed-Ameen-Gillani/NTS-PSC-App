import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class StudentLiveClassesScreen extends ConsumerWidget {
  const StudentLiveClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);

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
          'Live Masterclasses',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: AppColors.onBackground),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            final liveSessions = state.liveSessions;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promotional Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 8.w),
                                  SizedBox(width: 4.w),
                                  Text('LIVE BATCHES',
                                      style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 10.sp)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text('Interactive Mock Paper Sessions',
                            style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: Colors.white)),
                        SizedBox(height: 4.h),
                        Text('Join live video sessions with expert faculty to solve high-yield past papers in real-time.',
                            style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: Colors.white70)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text('Upcoming & Live Streams (${liveSessions.length})',
                      style: AppTextStyles.interBold24.copyWith(fontSize: 17.sp, color: AppColors.onBackground)),
                  SizedBox(height: 12.h),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: liveSessions.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final session = liveSessions[index];
                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: session.isLive ? Colors.red.shade300 : AppColors.grey300,
                            width: session.isLive ? 1.5.w : 1.w,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: session.isLive
                                        ? const Color(0xFFFFEBEE)
                                        : (session.isCompleted ? AppColors.grey300 : const Color(0xFFE3F2FD)),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    session.isLive ? '● LIVE NOW' : (session.isCompleted ? 'COMPLETED' : 'UPCOMING'),
                                    style: AppTextStyles.interSemiBold16.copyWith(
                                      fontSize: 10.sp,
                                      color: session.isLive
                                          ? Colors.red
                                          : (session.isCompleted ? AppColors.grey500 : AppColors.primary),
                                    ),
                                  ),
                                ),
                                Text(
                                  session.scheduledDate,
                                  style: AppTextStyles.interMedium16.copyWith(fontSize: 12.sp, color: AppColors.grey500),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(session.title, style: AppTextStyles.interBold24.copyWith(fontSize: 15.sp)),
                            SizedBox(height: 4.h),
                            Text(session.courseTitle,
                                style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.primary)),
                            if (session.description.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Text(session.description,
                                  style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500)),
                            ],
                            SizedBox(height: 14.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14.w, color: AppColors.grey500),
                                    SizedBox(width: 4.w),
                                    Text('${session.durationMinutes} mins',
                                        style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500)),
                                  ],
                                ),
                                if (session.isLive)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      CustomToast.showSuccess(context, message: 'Joining live classroom stream...');
                                    },
                                    icon: Icon(Icons.videocam, color: Colors.white, size: 16.w),
                                    label: Text('Join Live Room',
                                        style: AppTextStyles.interSemiBold16.copyWith(color: Colors.white, fontSize: 12.sp)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                      elevation: 0,
                                    ),
                                  )
                                else if (!session.isCompleted)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      CustomToast.showSuccess(context, message: 'Session reminder set for ${session.scheduledDate}!');
                                    },
                                    icon: Icon(Icons.notifications_active_outlined, size: 14.w, color: AppColors.primary),
                                    label: Text('Set Reminder',
                                        style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp, color: AppColors.primary)),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading live masterclasses')),
        ),
      ),
    );
  }
}
