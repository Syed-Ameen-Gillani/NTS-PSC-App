import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';

/// Course-wide legacy work has its own destination, never a lesson attachment.
class CourseScopedResourcesLink extends ConsumerWidget {
  const CourseScopedResourcesLink({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = CurriculumScope(courseId: courseId);
    final summary = ref.watch(curriculumAttachmentSummaryProvider(scope));
    if (summary.isLoading || summary.value?.isEmpty == true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Course resources'),
        subtitle: Text(
          summary.hasError
              ? 'Open to check course-wide work'
              : 'Course-wide files and final assessments',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.pushNamed(AppRoute.curriculumResources.name, extra: scope),
      ),
    );
  }
}
