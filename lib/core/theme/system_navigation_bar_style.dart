import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle systemNavigationBarStyle(Color background) =>
    SystemUiOverlayStyle(
      systemNavigationBarColor: background,
      systemNavigationBarDividerColor: background,
      systemNavigationBarIconBrightness:
          ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
