import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/config/routes/go_router.dart'; 

void main() {
  // Wrap the main app in ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

@override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // router configuration defined in router.dart
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}