// lib/core/theme/app_text_styles.dart

import 'dart:ui';

import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'DM Sans';

  static final TextStyle dmSans500med24 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.88,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );
  
   static final TextStyle dmSans500med12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF767372),
  );

}