import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherLiveClassesScreen extends ConsumerStatefulWidget {
  const TeacherLiveClassesScreen({super.key});

  @override
  ConsumerState<TeacherLiveClassesScreen> createState() => _TeacherLiveClassesScreenState();
}

class _TeacherLiveClassesScreenState extends ConsumerState<TeacherLiveClassesScreen> {
  void _showScheduleModal(BuildContext context) {
    final titleController = TextEditingController();
    final courseController = TextEditingController(text: 'FPSC Inspector Customs 2026 Batch');
    final dateController = TextEditingController(text: 'Tomorrow, 7:00 PM');
    final durationController = TextEditingController(text: '60');
    final linkController = TextEditingController(text: 'https://meet.google.com/fpsc-live-room');
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 24.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Schedule Live Masterclass', style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Session Topic / Title', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: titleController, hintText: 'e.g. Past Paper Solved Session 2025-2026', textInputAction: TextInputAction.next),
              SizedBox(height: 12.h),
              Text('Target Course', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: courseController, hintText: 'Course Name', textInputAction: TextInputAction.next),
              SizedBox(height: 12.h),
              Text('Date & Time', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: dateController, hintText: 'Date & Time', textInputAction: TextInputAction.next),
              SizedBox(height: 12.h),
              Text('Meeting / Stream URL (Zoom/Google Meet)', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: linkController, hintText: 'https://...', textInputAction: TextInputAction.next),
              SizedBox(height: 12.h),
              Text('Session Agenda / Objectives', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(controller: descController, hintText: 'Topics covered in this live session...', maxLines: 2),
              SizedBox(height: 20.h),
              CustomButton(
                text: 'Schedule & Notify Students',
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final session = LiveSessionModel(
                      id: 'live_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      courseTitle: courseController.text.trim(),
                      scheduledDate: dateController.text.trim(),
                      scheduledTime: '1 Hour',
                      durationMinutes: int.tryParse(durationController.text.trim()) ?? 60,
                      meetingUrl: linkController.text.trim(),
                      description: descController.text.trim(),
                      isLive: false,
                    );
                    ref.read(teacherControllerProvider.notifier).scheduleLiveSession(session);
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, message: 'Live class scheduled and announced to students!');
                  }
                },
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);

    return AppScaffold(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => _showScheduleModal(context),
          ),
          SizedBox(width: 8.w),
        ],
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
                  // Banner Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: Icon(Icons.videocam, color: Colors.white, size: 24.w),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Educora Live Studio',
                                  style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp, color: Colors.white)),
                              SizedBox(height: 2.h),
                              Text('Conduct live video workshops, solve past papers, and mentor your enrolled batches.',
                                  style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text('Scheduled Masterclasses (${liveSessions.length})',
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
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: session.isLive
                                        ? const Color(0xFFFFEBEE)
                                        : (session.isCompleted ? AppColors.grey300 : const Color(0xFFE3F2FD)),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (session.isLive) ...[
                                        Icon(Icons.circle, color: Colors.red, size: 8.w),
                                        SizedBox(width: 4.w),
                                      ],
                                      Text(
                                        session.isLive ? 'LIVE NOW' : (session.isCompleted ? 'COMPLETED' : 'UPCOMING'),
                                        style: AppTextStyles.interSemiBold16.copyWith(
                                          fontSize: 10.sp,
                                          color: session.isLive
                                              ? Colors.red
                                              : (session.isCompleted ? AppColors.grey500 : AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(child: Text(
                                  session.scheduledDate,
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.interMedium16.copyWith(fontSize: 12.sp, color: AppColors.grey500),
                                )),
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
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
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
                                      CustomToast.showSuccess(context, message: 'Launching live room stream...');
                                    },
                                    icon: Icon(Icons.videocam, color: Colors.white, size: 16.w),
                                    label: Text('Enter Live Room',
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
                                      CustomToast.showSuccess(context, message: 'Meeting URL copied: ${session.meetingUrl}');
                                    },
                                    icon: Icon(Icons.link, size: 14.w, color: AppColors.primary),
                                    label: Text('Copy Room Link',
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
          error: (_, __) => const Center(child: Text('Error loading live sessions')),
        ),
      ),
    );
  }
}
