import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'DM Sans';

  
  static const TextStyle dmSans500med24 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );
  
  static const TextStyle dmSans600med24 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  
  static const TextStyle dmSans500med17 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static final TextStyle dmSans500med12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF767372),
  );

  // --- Inter Font Styles ---
  static const String interFontFamily = 'Inter';

  static const TextStyle interBold30 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle interBold24 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle interSemiBold16 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle interMedium16 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle interRegular16 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle interRegular14 = TextStyle(
    fontFamily: interFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

}