import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Extend ConsumerWidget to use Riverpod capabilities
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), // hides the AppBar if needed
        child: SizedBox(),
      ),
      body: Center(
        child: Text(
          'Onboarding Screen UI ',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}