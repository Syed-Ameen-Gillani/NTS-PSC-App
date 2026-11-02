import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/data/course_certificate_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/certificate_open_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class CourseCertificateScreen extends ConsumerWidget {
  const CourseCertificateScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = courseCertificateProvider(courseId);
    final opening = ref.watch(certificateOpenProvider(courseId));
    final colors = Theme.of(context).colorScheme;
    return AppScaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: TextButton(
                    onPressed: () => ref.invalidate(provider),
                    child: const Text(
                      'Could not prepare your certificate. Retry',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              data: (certificate) => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 560.w),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
                    children: [
                      Text(
                        'Course completed',
                        style: AppTextStyles.interBold24.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your achievement, ready to share.',
                        style: AppTextStyles.interRegular14.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _CertificateAward(certificate: certificate),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            textStyle: AppTextStyles.interSemiBold16,
                          ),
                          icon: opening
                              ? SizedBox.square(
                                  dimension: 20.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                )
                              : const Icon(Icons.open_in_new_rounded),
                          label: Text(
                            opening
                                ? 'Opening certificate…'
                                : 'Open certificate PDF',
                          ),
                          onPressed: opening
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(
                                          certificateOpenProvider(
                                            courseId,
                                          ).notifier,
                                        )
                                        .open();
                                  } catch (_) {
                                    if (context.mounted) {
                                      CustomToast.showError(
                                        context,
                                        message:
                                            'Could not open certificate. Try again.',
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Save or share from your PDF viewer.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Text(
                        'Certificate ID',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 12.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SelectableText(
                        certificate.id,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _CertificateAward extends StatelessWidget {
  const _CertificateAward({required this.certificate});
  final CourseCertificate certificate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              color: colors.primary,
              size: 36.r,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'CERTIFICATE OF COMPLETION',
            textAlign: TextAlign.center,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 11.sp,
              letterSpacing: 1.2,
              color: colors.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            certificate.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.interBold24.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: 12.h),
          Text(
            'has successfully completed',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            certificate.course,
            textAlign: TextAlign.center,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 18.sp,
              color: colors.onSurface,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Divider(height: 1.h, color: colors.outlineVariant),
          ),
          Text(
            'Completed ${MaterialLocalizations.of(context).formatMediumDate(certificate.certificateDate)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'CBOA',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
