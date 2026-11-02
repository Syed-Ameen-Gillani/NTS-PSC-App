import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/discover_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

class InstructorsScreen extends ConsumerWidget {
  const InstructorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = AppConfig.isSupabaseEnabled
        ? ref.watch(publicTeacherPageIndexProvider)
        : 0;
    final instructors = AppConfig.isSupabaseEnabled
        ? ref
              .watch(publicTeacherPagesProvider(page))
              .whenData((pages) => pages.expand((part) => part).toList())
        : ref
              .watch(discoverControllerProvider)
              .whenData((state) => state.popularTeachers);
    return AppScaffold(
      appBar: AppBar(
        title: Text(
          'Instructors',
          style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.grey300),
        ),
      ),
      body: SafeArea(
        child: instructors.when(
          data: (state) {
            final teachers = state;
            if (teachers.isEmpty) {
              return const Center(child: Text('No instructors available yet.'));
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              itemCount:
                  teachers.length +
                  (AppConfig.isSupabaseEnabled &&
                          teachers.length == (page + 1) * publicTeacherPageSize
                      ? 1
                      : 0),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                if (index == teachers.length) {
                  return Center(
                    child: TextButton(
                      onPressed: ref
                          .read(publicTeacherPageIndexProvider.notifier)
                          .next,
                      child: const Text('Show more'),
                    ),
                  );
                }
                final teacher = teachers[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  leading: AppAvatar(
                    size: 52.w,
                    imagePath: teacher.imagePath,
                    name: teacher.name,
                  ),
                  title: Text(
                    teacher.name,
                    style: AppTextStyles.interSemiBold16,
                  ),
                  subtitle: teacher.subject.trim().isEmpty
                      ? null
                      : Text(
                          teacher.subject,
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.grey500,
                    size: 20.r,
                  ),
                  onTap: () => context.pushNamed(
                    AppRoute.publicTeacherProfile.name,
                    extra: teacher,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () {
                if (AppConfig.isSupabaseEnabled) {
                  ref.invalidate(publicTeacherPageProvider(page));
                } else {
                  ref.invalidate(discoverControllerProvider);
                }
              },
              child: const Text('Could not load instructors. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}
