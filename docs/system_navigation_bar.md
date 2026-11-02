# System Navigation Bar

Screens use `AppScaffold` from `lib/presentation/widgets/app_scaffold.dart`.
It delegates layout and behavior to Flutter's Scaffold and coordinates the
system navigation area with the screen background.

- Explicit `backgroundColor` values take precedence. Otherwise the active
  `ThemeData.scaffoldBackgroundColor` is used and follows theme updates.
- Navigation icons use contrast appropriate to the resolved background.
- Navigation divider color matches the background; Android's navigation-bar
  contrast scrim is disabled.
- Edge-to-edge Android requires painting behind the system bar because native
  navigation-bar color settings may be ignored. The shared scaffold paints only
  its unconsumed bottom safe-area inset, without intercepting touches.
- Nested tab scaffolds respect consumed safe-area padding. Keyboard insets are
  left to the IME rather than being covered by the application's bottom strip.
- Per-screen annotations restore the appropriate navigation style on push/pop.
  App bars continue to control status-bar presentation.

The root builder provides a theme-derived fallback. The former fixed white
startup/overlay style has been removed, and startup explicitly uses edge-to-edge.

Theme selection is unchanged: the current application selects its light theme.
This change supports both light and dark active themes without introducing an
app-wide dark-mode redesign or a new theme selector.

Verification includes theme changes, explicit backgrounds, keyboard insets,
push/pop restoration, and nested bottom-navigation layouts in
`test/system_navigation_bar_test.dart`.

Verification results: all five targeted tests passed. The full suite finished
with 101 passed, one skipped, and three stale text-expectation failures: two
profile-photo label checks and one legacy login error message. Responsive route
checks passed. The new shared components analyze cleanly; whole-project analysis
still reports 47 existing warning/information findings. No Android device or
emulator was connected for a native visual check.

Reference: [Flutter edge-to-edge system UI behavior](https://api.flutter.dev/flutter/services/SystemChrome/setSystemUIOverlayStyle.html).
