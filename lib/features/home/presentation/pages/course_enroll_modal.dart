import 'package:flutter/material.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/catalog_pages_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final _enrollmentBusy = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);
final _paymentSelection = StateProvider.autoDispose.family<int, String>(
  (ref, id) => 0,
);

class CourseEnrollModal extends ConsumerStatefulWidget {
  final CourseModel course;

  const CourseEnrollModal({super.key, required this.course});

  @override
  ConsumerState<CourseEnrollModal> createState() => _CourseEnrollModalState();
}

class _CourseEnrollModalState extends ConsumerState<CourseEnrollModal> {
  int get _selectedPaymentMethod =>
      ref.read(_paymentSelection(widget.course.id));
  set _selectedPaymentMethod(int value) =>
      ref.read(_paymentSelection(widget.course.id).notifier).state = value;
  bool get _isProcessing => ref.read(_enrollmentBusy(widget.course.id));
  set _isProcessing(bool value) =>
      ref.read(_enrollmentBusy(widget.course.id).notifier).state = value;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'title': 'Easypaisa Mobile Wallet',
      'subtitle': 'Instant checkout via Easypaisa account',
      'icon': Icons.account_balance_wallet_outlined,
      'badge': 'Popular',
    },
    {
      'title': 'JazzCash Mobile Account',
      'subtitle': 'Pay with your JazzCash registered number',
      'icon': Icons.phone_android_outlined,
      'badge': null,
    },
    {
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, Mastercard & PayPak accepted',
      'icon': Icons.credit_card_outlined,
      'badge': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(_enrollmentBusy(widget.course.id));
    ref.watch(_paymentSelection(widget.course.id));
    final isPaidRemoteCourse =
        AppConfig.isSupabaseEnabled &&
        (widget.course.priceAmount != null
            ? widget.course.priceAmount! > 0
            : widget.course.price != 'Free');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirm Enrollment',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 20.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grey500),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Course preview card
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.grey300, width: 1.w),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: DashboardCourseCover(
                      imagePath: widget.course.imagePath,
                      coverUrl: widget.course.coverUrl,
                      width: 64.w,
                      height: 64.w,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.title,
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.onBackground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Instructor: ${widget.course.author}',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.course.price.isNotEmpty
                        ? widget.course.price
                        : 'Free',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            if (AppConfig.isSupabaseEnabled)
              Text(
                isPaidRemoteCourse
                    ? 'Paid enrollment is not available yet.'
                    : 'Free enrollment',
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.onBackground,
                ),
              )
            else ...[
              // Select Payment Method
              Text(
                'Select Payment Method (Mock Sandbox)',
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 12.h),

              Column(
                children: List.generate(_paymentMethods.length, (index) {
                  final item = _paymentMethods[index];
                  final isSelected = _selectedPaymentMethod == index;

                  return GestureDetector(
                    onTap: () => _selectedPaymentMethod = index,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey300,
                          width: isSelected ? 1.5.w : 1.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey500,
                            size: 24.w,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 13.sp,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                Text(
                                  item['subtitle'] as String,
                                  style: AppTextStyles.interRegular14.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RadioGroup<int>(
                            groupValue: _selectedPaymentMethod,
                            onChanged: (val) {
                              if (val != null) _selectedPaymentMethod = val;
                            },
                            child: Radio<int>(
                              value: index,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
            SizedBox(height: 16.h),

            // Submit Button
            CustomButton(
              text: _isProcessing
                  ? 'Enrolling...'
                  : isPaidRemoteCourse
                  ? 'Enrollment unavailable'
                  : 'Confirm & Start Learning',
              color: isPaidRemoteCourse ? AppColors.grey500 : AppColors.primary,
              onPressed: _isProcessing
                  ? () {}
                  : () async {
                      if (isPaidRemoteCourse) return;
                      if (AppConfig.isSupabaseEnabled) {
                        final studentId = ref
                            .read(authControllerProvider)
                            .value
                            ?.user
                            ?.id;
                        if (studentId == null) {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.goNamed(AppRoute.login.name);
                          return;
                        }
                        _isProcessing = true;
                        try {
                          final repo = ref.read(courseRepositoryProvider);
                          final enrolled = await repo.enrollInCourse(
                            widget.course.id,
                            studentId,
                          );
                          if (!enrolled) {
                            throw StateError('Enrollment is not active.');
                          }
                          final updated = await repo.getCourseById(
                            widget.course.id,
                          );
                          if (updated == null) {
                            throw StateError('Course is no longer available.');
                          }
                          await ref
                              .read(myLearningControllerProvider.notifier)
                              .enrollCourse(updated);
                          ref.invalidate(homeControllerProvider);
                          ref.invalidate(publishedCatalogProvider);
                          ref.invalidate(featuredCatalogProvider);
                          ref.invalidate(catalogPageProvider);
                          ref.invalidate(discoverControllerProvider);
                          if (context.mounted) {
                            Navigator.of(context).pop(updated);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            CustomToast.showError(
                              context,
                              message: 'Could not enroll in this course',
                            );
                          }
                        } finally {
                          if (mounted) _isProcessing = false;
                        }
                        return;
                      }
                      _isProcessing = true;
                      final repo = ref.read(courseRepositoryProvider);
                      await repo.enrollInCourse(widget.course.id, 'student_1');
                      ref
                          .read(myLearningControllerProvider.notifier)
                          .enrollCourse(widget.course);
                      _isProcessing = false;

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        CustomToast.showSuccess(
                          context,
                          message:
                              'Successfully enrolled in ${widget.course.title}!',
                        );
                        context.pushNamed(
                          AppRoute.lessonPlayer.name,
                          extra: {
                            'course': widget.course,
                            'lesson':
                                widget.course.modules.isNotEmpty &&
                                    widget
                                        .course
                                        .modules
                                        .first
                                        .lessons
                                        .isNotEmpty
                                ? widget.course.modules.first.lessons.first
                                : LessonModel(
                                    id: 'l1',
                                    title: 'Introduction & Course Roadmap',
                                    durationMinutes: 15,
                                    notes:
                                        'Welcome to this course! Start watching the foundational lectures.',
                                  ),
                          },
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
