import 'package:flutter/material.dart';

class AppGradients {
  static LinearGradient primaryBanner(ColorScheme colors) => LinearGradient(
    colors: [
      Color.lerp(colors.primary, colors.secondary, 0.2)!,
      colors.primary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
