import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/app_image_provider.dart';

/// User avatar with a consistent neutral fallback when no profile image exists.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.size,
    this.imagePath = '',
    this.imageProvider,
    this.name = '',
  });

  final double size;
  final String imagePath;
  final ImageProvider<Object>? imageProvider;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? null : name.trim()[0].toUpperCase();
    final fallback = Center(
      child: initial == null
          ? Icon(Icons.person_outline_rounded, size: size * .44)
          : Text(
              initial,
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: size * .38,
                color: AppColors.grey600,
              ),
            ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.settingsCardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.settingsCardBorder, width: 1.w),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageProvider == null && imagePath.trim().isEmpty
          ? fallback
          : Image(
              image: imageProvider ?? appImageProvider(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
