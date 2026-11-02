import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/features/home/presentation/pages/home_screen.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/discover_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/my_learning_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quizzes_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const MyLearningScreen(),
    const QuizzesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = AppConfig.isSupabaseEnabled &&
        ref.watch(authControllerProvider).value?.user == null;
    final currentIndex = isGuest ? _currentIndex.clamp(0, 1) : _currentIndex;
    return AppScaffold(
      body: IndexedStack(
        index: currentIndex,
        children: isGuest ? _screens.take(2).toList() : _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.grey300, width: 1.w)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (isGuest && index == 2) {
              context.pushNamed(AppRoute.login.name);
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey500,
          selectedLabelStyle: AppTextStyles.interMedium16.copyWith(fontSize: 10.sp),
          unselectedLabelStyle: AppTextStyles.interRegular14.copyWith(fontSize: 10.sp),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppAssets.homeIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                AppAssets.homeIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppAssets.discoverIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                AppAssets.discoverIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: 'Discover',
            ),
            if (isGuest)
              const BottomNavigationBarItem(
                icon: Icon(Icons.login_outlined),
                label: 'Sign In',
              ),
            if (!isGuest) ...[
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppAssets.learnIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                AppAssets.learnIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppAssets.quizzIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                AppAssets.quizzIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: 'Quizzes',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppAssets.profileIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.grey500, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                AppAssets.profileIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
              label: 'Profile',
            ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
