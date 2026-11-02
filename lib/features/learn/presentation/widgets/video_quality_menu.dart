import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

/// Uploaded and offline lessons currently contain one encoded source, not a
/// rendition ladder. Report that source without inventing selectable resolutions.
class VideoQualityMenu extends StatelessWidget {
  const VideoQualityMenu({
    super.key,
    required this.size,
    required this.onOpened,
    required this.onClosed,
  });

  final Size size;
  final VoidCallback onOpened;
  final VoidCallback onClosed;

  static String sourceLabel(Size size) {
    final height = math.min(size.width, size.height);
    return height.isFinite && height > 0
        ? 'Original (${height.round()}p)'
        : 'Original';
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Video quality',
    color: Theme.of(context).colorScheme.surface,
    icon: Icon(
      Icons.high_quality_outlined,
      color: AppColors.videoForeground,
      size: 22.r.clamp(18, 26),
    ),
    onOpened: onOpened,
    onCanceled: onClosed,
    onSelected: (_) => onClosed(),
    itemBuilder: (_) => [
      CheckedPopupMenuItem(
        value: 'original',
        checked: true,
        child: Text(sourceLabel(size)),
      ),
    ],
  );
}
