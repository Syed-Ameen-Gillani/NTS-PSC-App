import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';
import 'package:nts_psc_app/features/auth/presentation/utils/auth_error_messages.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> startSocialSignIn(
  BuildContext context,
  WidgetRef ref,
  OAuthProvider provider,
) async {
  try {
    await ref.read(authIntegrationsProvider).signIn(provider);
  } catch (error) {
    if (context.mounted) {
      CustomToast.showError(
        context,
        message: socialSignInErrorMessage(error, provider),
      );
    }
  }
}
