import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_courses_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_dashboard_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_profile_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';

class TeacherMainTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final teacherMainTabProvider = NotifierProvider<TeacherMainTab, int>(
  TeacherMainTab.new,
);

class TeacherMainScreen extends ConsumerStatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  ConsumerState<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends ConsumerState<TeacherMainScreen>
    with RestorationMixin {
  late final RestorableInt _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = RestorableInt(ref.read(teacherMainTabProvider));
  }

  @override
  String get restorationId => 'teacher-main';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentIndex, 'tab');
    // Publish after restoration so programmatic tab switches keep working.
    Future.microtask(() {
      if (mounted) {
        ref.read(teacherMainTabProvider.notifier).select(_currentIndex.value);
      }
    });
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  static const _screens = [
    TeacherDashboardScreen(),
    TeacherCoursesScreen(),
    TeacherQuizStudioScreen(),
    TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(teacherMainTabProvider, (_, next) {
      if (next != _currentIndex.value) {
        setState(() => _currentIndex.value = next);
      }
    });
    final currentIndex = _currentIndex.value;
    return AppScaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.grey300, width: 1.w),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: ref.read(teacherMainTabProvider.notifier).select,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.background,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey500,
            selectedLabelStyle: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 10.sp,
            ),
            unselectedLabelStyle: AppTextStyles.interRegular14.copyWith(
              fontSize: 10.sp,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz_outlined),
                activeIcon: Icon(Icons.quiz),
                label: 'Assessments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
