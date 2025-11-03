
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Still navigate after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/o1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // specific background color
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        // The white container for the logo
        child: Container(
          padding: const EdgeInsets.all(20.0), // Padding inside the container
          decoration: BoxDecoration(
            color: kWhiteContainerColor,
            // Highly rounded border radius matching the design
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          //  logo asset inside the container
          child: Image.asset(
            'assets/images/logo.png',
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
