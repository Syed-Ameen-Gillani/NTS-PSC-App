// lib/features/home/widgets/bottomnavbar.dart
// Bottom Navigation Bar Widget using circle_nav_bar package

import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/features/home/providers/navbarproviddr.dart';

/// Bottom Navigation Bar widget using circle_nav_bar package
/// Manages 5 navigation items: Home, Course, Search, Saved, Profile
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  static const Color kPrimaryBlue = Color(0xFF3787FF);
  static const Color kTextSecondary = Color(0xFF767372);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);

    return CircleNavBar(
      activeIcons: const [
        Icon(Icons.home, color: Colors.white),
        Icon(Icons.book, color: Colors.white),
        Icon(Icons.search, color: Colors.white),
        Icon(Icons.bookmark, color: Colors.white),
        Icon(Icons.person, color: Colors.white),
      ],
      inactiveIcons: [
        Icon(Icons.home_outlined, color: kTextSecondary),
        Icon(Icons.book_outlined, color: kTextSecondary),
        Icon(Icons.search_outlined, color: kTextSecondary),
        Icon(Icons.bookmark_border, color: kTextSecondary),
        Icon(Icons.person_outline, color: kTextSecondary),
      ],
      color: Colors.white,
      circleColor: kPrimaryBlue,
      height: 60.h,
      circleWidth: 60.w,
      activeIndex: selectedIndex,
      onTap: (index) {
        ref.read(bottomNavProvider.notifier).setSelectedIndex(index);
      },
      // padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      cornerRadius: BorderRadius.zero,
      shadowColor: Colors.black.withOpacity(0.05),
      elevation: 10,
    );
  }
}
