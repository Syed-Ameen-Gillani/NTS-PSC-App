import 'package:flutter/material.dart';

ImageProvider<Object> appImageProvider(String path) {
  final uri = Uri.tryParse(path);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    return NetworkImage(path);
  }
  return AssetImage(path);
}
