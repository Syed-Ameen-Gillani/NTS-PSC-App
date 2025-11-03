
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
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
        );
      },

      child: const SplashScreen(),
    );
  }
}
