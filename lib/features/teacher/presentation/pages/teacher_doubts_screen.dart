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

class TeacherDoubtsScreen extends ConsumerStatefulWidget {
  const TeacherDoubtsScreen({super.key});

  @override
  ConsumerState<TeacherDoubtsScreen> createState() => _TeacherDoubtsScreenState();
}

class _TeacherDoubtsScreenState extends ConsumerState<TeacherDoubtsScreen> {
  int _selectedTab = 0; // 0: Unanswered, 1: Resolved

  void _showAnswerBottomSheet(BuildContext context, StudentDoubtModel doubt) {
    final answerController = TextEditingController();

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
                  Text('Answer Student Doubt', style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Question (${doubt.studentName}):',
                        style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp, color: AppColors.primary)),
                    SizedBox(height: 4.h),
                    Text(doubt.question, style: AppTextStyles.interRegular14.copyWith(fontSize: 13.sp)),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text('Your Explanation & Guidance', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              CustomTextFormField(
                controller: answerController,
                hintText: 'Type your detailed answer, referencing the relevant exam law or topic...',
                maxLines: 4,
              ),
              SizedBox(height: 20.h),
              CustomButton(
                text: 'Send Explanation',
                onPressed: () {
                  if (answerController.text.trim().isNotEmpty) {
                    ref.read(teacherControllerProvider.notifier).answerDoubt(doubt.id, answerController.text.trim());
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, message: 'Answer sent to ${doubt.studentName}!');
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
          'Student Doubts & Q&A',
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
            final doubts = _selectedTab == 0
                ? state.doubts.where((d) => !d.isResolved).toList()
                : state.doubts.where((d) => d.isResolved).toList();

            return Column(
              children: [
                // Top Tab Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppColors.primary : AppColors.grey100,
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Unanswered (${state.doubts.where((d) => !d.isResolved).length})',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 13.sp,
                                color: _selectedTab == 0 ? Colors.white : AppColors.grey500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppColors.primary : AppColors.grey100,
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Resolved (${state.doubts.where((d) => d.isResolved).length})',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 13.sp,
                                color: _selectedTab == 1 ? Colors.white : AppColors.grey500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Doubts List
                Expanded(
                  child: doubts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 48.w, color: AppColors.primary),
                              SizedBox(height: 12.h),
                              Text(
                                _selectedTab == 0 ? 'All student doubts resolved!' : 'No resolved doubts yet.',
                                style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                          itemCount: doubts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 16.h),
                          itemBuilder: (context, index) {
                            final doubt = doubts[index];
                            return Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.grey300, width: 1.w),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14.r,
                                            backgroundColor: AppColors.primary,
                                            child: Text(
                                              doubt.studentName.isNotEmpty ? doubt.studentName[0] : 'S',
                                              style: const TextStyle(color: Colors.white, fontSize: 11),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(doubt.studentName,
                                              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                                        ],
                                      ),
                                      Text(doubt.createdAt,
                                          style: AppTextStyles.interRegular14
                                              .copyWith(fontSize: 11.sp, color: AppColors.grey400)),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    '${doubt.courseTitle} • ${doubt.lessonTitle}',
                                    style: AppTextStyles.interRegular14
                                        .copyWith(fontSize: 11.sp, color: AppColors.primary),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(doubt.question,
                                      style: AppTextStyles.interRegular14
                                          .copyWith(fontSize: 13.sp, color: AppColors.onBackground)),
                                  if (doubt.isResolved && doubt.answer != null) ...[
                                    SizedBox(height: 12.h),
                                    Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.verified, size: 14.w, color: AppColors.primary),
                                              SizedBox(width: 4.w),
                                              Text('Your Answer:',
                                                  style: AppTextStyles.interSemiBold16
                                                      .copyWith(fontSize: 11.sp, color: AppColors.primary)),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(doubt.answer!,
                                              style: AppTextStyles.interRegular14
                                                  .copyWith(fontSize: 12.sp, color: AppColors.onBackground)),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    SizedBox(height: 12.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAnswerBottomSheet(context, doubt),
                                        icon: Icon(Icons.reply, size: 14.w, color: Colors.white),
                                        label: Text('Reply & Resolve',
                                            style: AppTextStyles.interSemiBold16
                                                .copyWith(color: Colors.white, fontSize: 12.sp)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading doubts')),
        ),
      ),
    );
  }
}
