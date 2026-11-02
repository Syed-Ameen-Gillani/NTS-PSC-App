import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/widgets/profile_edit_form.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher =
        ref.watch(authControllerProvider).value?.selectedRole ==
        UserRole.teacher;
    final profile = ref.watch(profileControllerProvider);
    final isSaving = ref.watch(editProfileSavingProvider);

    return PopScope(
      canPop: !isSaving,
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: isSaving,
            child: AppScaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.grey900,
                    size: 20.w,
                  ),
                  onPressed: isSaving ? null : () => context.pop(),
                ),
                titleSpacing: 0,
                title: Text(
                  'Edit Profile',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 20.sp,
                    color: AppColors.grey900,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1.h),
                  child: Container(color: AppColors.grey300, height: 1.h),
                ),
              ),
              body: SafeArea(
                child: profile.when(
                  data: (user) => ProfileEditForm(
                    key: ValueKey(user.id),
                    user: user,
                    isTeacher: isTeacher,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      const Center(child: Text('Error loading profile')),
                ),
              ),
            ),
          ),
          if (isSaving) ...[
            const ModalBarrier(dismissible: false, color: Color(0x24000000)),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
