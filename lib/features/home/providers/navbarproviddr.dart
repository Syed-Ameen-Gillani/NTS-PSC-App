// lib/features/home/providers/navbarproviddr.dart
// Bottom Navigation Bar State Provider using Riverpod code generation

import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'navbarproviddr.g.dart';

/// Provider to manage the bottom navigation bar state
/// Manages the currently selected tab index (0-4)
/// 0: Home, 1: Course, 2: Search, 3: Saved, 4: Profile
@riverpod
class BottomNavNotifier extends _$BottomNavNotifier {
  @override
  int build() {
    // Initial state: Home tab is selected
    return 0;
  }

  /// Update the selected tab index
  void setSelectedIndex(int index) {
    if (index >= 0 && index <= 4) {
      state = index;
    }
  }
}
