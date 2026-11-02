import 'package:flutter/widgets.dart';

final _rightToLeftScript = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
);

TextDirection contentTextDirection(String text) =>
    _rightToLeftScript.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
