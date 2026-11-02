import 'package:flutter/material.dart';

final ScrollBehavior keyboardDismissScrollBehavior =
    const MaterialScrollBehavior().copyWith(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );

void dismissKeyboardOnTapOutside(PointerDownEvent _) {
  FocusManager.instance.primaryFocus?.unfocus();
}
