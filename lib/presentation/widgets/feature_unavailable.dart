import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class FeatureUnavailable extends StatelessWidget {
  const FeatureUnavailable({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 32.w, color: AppColors.grey500),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular16.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    ),
  );
}

class FeatureUnavailableScreen extends StatelessWidget {
  const FeatureUnavailableScreen({
    super.key,
    required this.title,
    required this.message,
  });
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: Text(
        title,
        style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.goNamed(AppRoute.main.name),
      ),
    ),
    body: SafeArea(child: FeatureUnavailable(message: message)),
  );
}
