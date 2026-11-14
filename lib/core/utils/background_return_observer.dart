import 'package:flutter/widgets.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';

/// A focus interruption (notification shade/dialog) is not a background return.
class BackgroundReturnObserver with WidgetsBindingObserver {
  BackgroundReturnObserver(this.onReturn);
  final VoidCallback onReturn;
  bool _backgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LifecycleDiagnostics.event('lifecycle', state.name);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed) {
      final shouldNotify = _backgrounded;
      _backgrounded = false;
      if (shouldNotify) onReturn();
    } else if (state == AppLifecycleState.detached) {
      _backgrounded = false;
    }
  }
}
