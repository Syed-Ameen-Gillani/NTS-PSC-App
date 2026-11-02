import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final _resetBusyProvider = StateProvider.autoDispose<bool>((ref) => false);

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(_resetBusyProvider);
    return AppScaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Choose a new password', style: AppTextStyles.interBold24),
                SizedBox(height: 24.h),
                CustomTextFormField(
                  controller: _password,
                  hintText: 'New password',
                  textInputAction: TextInputAction.next,
                  isPassword: true,
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                SizedBox(height: 16.h),
                CustomTextFormField(
                  controller: _confirm,
                  hintText: 'Confirm password',
                  textInputAction: TextInputAction.done,
                  isPassword: true,
                  validator: (value) =>
                      value != _password.text ? 'Passwords must match.' : null,
                ),
                SizedBox(height: 24.h),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!_form.currentState!.validate()) return;
                          ref.read(_resetBusyProvider.notifier).state = true;
                          try {
                            await ref
                                .read(authIntegrationsProvider)
                                .updatePassword(_password.text);
                            if (!context.mounted) return;
                            CustomToast.showSuccess(
                              context,
                              message: 'Password updated. Sign in again.',
                            );
                            context.goNamed(AppRoute.login.name);
                          } catch (error) {
                            if (context.mounted) {
                              CustomToast.showError(
                                context,
                                message: error is StateError
                                    ? error.message
                                    : 'Recovery link expired or password update failed. Request a new link.',
                              );
                            }
                          } finally {
                            if (mounted) {
                              ref.read(_resetBusyProvider.notifier).state =
                                  false;
                            }
                          }
                        },
                  child: Text(busy ? 'Updating...' : 'Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
