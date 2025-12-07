// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navbarproviddr.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to manage the bottom navigation bar state
/// Manages the currently selected tab index (0-4)
/// 0: Home, 1: Course, 2: Search, 3: Saved, 4: Profile

@ProviderFor(BottomNavNotifier)
const bottomNavProvider = BottomNavNotifierProvider._();

/// Provider to manage the bottom navigation bar state
/// Manages the currently selected tab index (0-4)
/// 0: Home, 1: Course, 2: Search, 3: Saved, 4: Profile
final class BottomNavNotifierProvider
    extends $NotifierProvider<BottomNavNotifier, int> {
  /// Provider to manage the bottom navigation bar state
  /// Manages the currently selected tab index (0-4)
  /// 0: Home, 1: Course, 2: Search, 3: Saved, 4: Profile
  const BottomNavNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottomNavProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottomNavNotifierHash();

  @$internal
  @override
  BottomNavNotifier create() => BottomNavNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$bottomNavNotifierHash() => r'4788b540f7118b3f712ed0e26856b3d926f8c982';

/// Provider to manage the bottom navigation bar state
/// Manages the currently selected tab index (0-4)
/// 0: Home, 1: Course, 2: Search, 3: Saved, 4: Profile

abstract class _$BottomNavNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
