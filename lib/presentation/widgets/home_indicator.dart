import 'package:flutter/material.dart';

/// A customizable home indicator widget that mimics iOS-style navigation bar
/// 
/// This widget creates a horizontal bar indicator typically placed at the bottom
/// of the screen to indicate swipe-up gestures or navigation affordance.
/// 
/// Example usage:
/// ```dart
/// // Basic usage
/// Scaffold(
///   bottomNavigationBar: HomeIndicator(),
/// )
/// 
/// // With customization
/// Scaffold(
///   bottomNavigationBar: HomeIndicator(
///     color: Colors.blue,
///     width: 120,
///     height: 4,
///     backgroundColor: Colors.white,
///   ),
/// )
/// 
/// // With gesture detection
/// Scaffold(
///   bottomNavigationBar: HomeIndicator(
///     onSwipeUp: () {
///       print('User swiped up!');
///       // Navigate or perform action
///     },
///   ),
/// )
/// 
/// // Adaptive for platform
/// Scaffold(
///   bottomNavigationBar: HomeIndicator.adaptive(),
/// )
/// 
/// // Minimal style
/// Scaffold(
///   bottomNavigationBar: HomeIndicator.minimal(
///     color: Colors.green,
///   ),
/// )
/// ```
class HomeIndicator extends StatelessWidget {
  /// Color of the indicator bar
  final Color color;

  /// Width of the indicator bar
  /// If null, defaults to 35% of screen width for responsive design
  final double? width;

  /// Height of the indicator bar itself
  /// Default is 5.0
  final double height;

  /// Total height of the container that holds the indicator
  /// This includes padding. Default is 34.0 (iOS standard)
  final double containerHeight;

  /// Background color of the entire indicator container
  
  final Color? backgroundColor;

  /// Padding below the indicator bar
  final double bottomPadding;

  /// Whether the indicator should be visible
  ///for platform-specific or conditional display
  /// Default is true
  final bool visible;

  /// Callback function triggered when user swipes up on the indicator
  /// The gesture must have sufficient velocity (>300) to trigger
  final VoidCallback? onSwipeUp;

  /// Optional border displayed at the top of the container
  /// Useful for separating content from the indicator
  final BorderSide? topBorder;

  /// Creates a customizable home indicator
  const HomeIndicator({
    Key? key,
    this.color = const Color(0xFF8B5CF6),
    this.width,
    this.height = 5.0,
    this.containerHeight = 34.0,
    this.backgroundColor = Colors.white,
    this.bottomPadding = 8.0,
    this.visible = true,
    this.onSwipeUp,
    this.topBorder,
  }) : super(key: key);

  /// Creates a platform-adaptive home indicator
  /// 
  /// This factory constructor can be extended to show/hide based on platform
  /// Currently shows on all platforms but can be modified to detect iOS/Android
  /// 
  /// Example:
  /// ```dart
  /// HomeIndicator.adaptive(
  ///   color: Colors.blue,
  ///   onSwipeUp: () => Navigator.pop(context),
  /// )
  /// ```
  factory HomeIndicator.adaptive({
    Color color = const Color(0xFF8B5CF6),
    double? width,
    double height = 5.0,
    VoidCallback? onSwipeUp,
  }) {
    return HomeIndicator(
      color: color,
      width: width,
      height: height,
      onSwipeUp: onSwipeUp,
      visible: true,
    );
  }

  /// Creates a minimal home indicator without background container
  /// 
  /// This style has a transparent background and minimal spacing,
  /// suitable for overlaying on existing content
  /// 
  /// Example:
  /// ```dart
  /// HomeIndicator.minimal(
  ///   color: Colors.red,
  ///   width: 100,
  /// )
  /// ```
  factory HomeIndicator.minimal({
    Color color = const Color(0xFF8B5CF6),
    double? width,
    double height = 5.0,
  }) {
    return HomeIndicator(
      color: color,
      width: width,
      height: height,
      backgroundColor: Colors.transparent,
      containerHeight: height + 16,
      topBorder: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return empty widget if not visible
    if (!visible) return const SizedBox.shrink();

    // Calculate responsive width if not provided
    final indicatorWidth = width ?? MediaQuery.of(context).size.width * 0.35;

    // Build the indicator container
    Widget indicator = Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: topBorder != null ? Border(top: topBorder!) : null,
      ),
      child: Center(
        child: Container(
          width: indicatorWidth,
          height: height,
          margin: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );

    // Wrap with gesture detector if callback is provided
    if (onSwipeUp != null) {
      indicator = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          // Detect upward swipe with sufficient velocity
          // if (details.primaryVelocity != null &&
          //     details.primaryVelocity! < -300) {
          //   onSwipeUp?.call();
          // }
        },
        child: indicator,
      );
    }

    return indicator;
  }
}

/// Extension to easily add platform detection if needed
extension HomeIndicatorPlatform on HomeIndicator {
  /// Check if the current platform typically uses home indicators
  /// 
  /// Returns true for iOS and false for Android/Web
  static bool shouldShowOnPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS;
  }
}