import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/account_created_success_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/check_email_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/forgot_password_email_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/login_page.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/registration_success_modal.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/signup_create_account_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/signup_details_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/signup_method_selection_screen.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_4.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_6.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/welcome_role_screen.dart';
import 'package:nts_psc_app/features/splash/splash_screen.dart';

// void main() {
//   runApp(const ProviderScope(child: MyApp()));
// }

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Use ref to watch the router provider if needed, but for now, we use the instance
//     final router = appRouter;

//     return ScreenUtilInit(
//       designSize: const Size(414, 896), // Use your Figma size
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MaterialApp.router(
//           // Use Go Router config here
//           routerConfig: router,
//           debugShowCheckedModeBanner: false,
//            theme: appTheme(context),
//         );
//       },
//     );
//   }
// }

//temporary main.dart without go_router, so that onboarding screens can be tested directly

//lib/main.dart (Temporary Testing Setup)

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          home: child,

          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        );
      },

      child: SignupMethodSelectionScreen(),
    );
  }
}

