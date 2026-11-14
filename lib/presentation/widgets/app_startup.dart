import 'package:flutter/material.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';

/// Draws the first frame while the authenticated session is being recovered.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key, required this.initialize, required this.child});

  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
    } catch (error) {
      LifecycleDiagnostics.event('startup', 'failed ${error.runtimeType}');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.child;
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.appLogo, width: 200, height: 200),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Could not start the app. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () {
                        final ready = _initialize();
                        setState(() {
                          _ready = ready;
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
