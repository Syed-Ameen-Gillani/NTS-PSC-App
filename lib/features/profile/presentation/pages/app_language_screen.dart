import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class AppLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'English (US)';

  void setLanguage(String language) {
    state = language;
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, String>(() {
  return AppLanguageNotifier();
});

class AppLanguageScreen extends ConsumerWidget {
  const AppLanguageScreen({super.key});

  final List<Map<String, String>> languages = const [
    {'title': 'English (US)', 'subtitle': 'English (US)'},
    {'title': 'English (UK)', 'subtitle': 'English (UK)'},
    {'title': 'Urdu', 'subtitle': 'اردو'},
    {'title': 'Spanish', 'subtitle': 'Español'},
    {'title': 'French', 'subtitle': 'Français'},
    {'title': 'German', 'subtitle': 'Deutsch'},
    {'title': 'Arabic', 'subtitle': 'العربية'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.grey900, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'App Language',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.grey900,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your preferred language for the app interface.',
                style: AppTextStyles.interRegular16.copyWith(
                  color: AppColors.grey500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.grey300, width: 1.w),
                ),
                child: Column(
                  children: List.generate(languages.length, (index) {
                    final lang = languages[index];
                    final isSelected = selectedLanguage == lang['title'];
                    final isLast = index == languages.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            if (!isSelected) {
                              ref.read(appLanguageProvider.notifier).setLanguage(lang['title']!);
                              CustomToast.showInfo(context, message: 'Language updated to ${lang['title']}');
                            }
                          },
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(index == 0 ? 24.r : 0),
                            bottom: Radius.circular(isLast ? 24.r : 0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['title']!,
                                      style: AppTextStyles.interSemiBold16.copyWith(
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      lang['subtitle']!,
                                      style: AppTextStyles.interRegular14.copyWith(
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 24.w,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            color: AppColors.grey300,
                            height: 1.h,
                            thickness: 1.h,
                          ),
                      ],
                    );
                  }),
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
