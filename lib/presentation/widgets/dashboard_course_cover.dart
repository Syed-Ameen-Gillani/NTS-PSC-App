import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

class DashboardCourseCover extends StatelessWidget {
  const DashboardCourseCover({
    super.key,
    required this.imagePath,
    this.coverUrl,
    required this.width,
    required this.height,
  });

  final String imagePath;
  final String? coverUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isSupabaseEnabled) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    final url = Uri.tryParse(coverUrl ?? '');
    if (url != null && url.scheme == 'https' && url.host.isNotEmpty) {
      return Image.network(
        url.toString(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.grey100,
    alignment: Alignment.center,
    child: Icon(Icons.menu_book_outlined, color: AppColors.grey500, size: 32.w),
  );
}
