part of 'curriculum_resources_screen.dart';

extension _OwnerMaterialSection on _Content {
  Widget _buildOwnerMaterialSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CurriculumMaterial>> materialsAsync,
  ) => materialsAsync.when(
    loading: () => Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: const CircularProgressIndicator(),
      ),
    ),
    error: (_, _) => Center(
      child: TextButton.icon(
        onPressed: () =>
            ref.invalidate(curriculumMaterialsProvider(details.scope)),
        icon: const Icon(Icons.refresh),
        label: const Text('Retry Materials'),
      ),
    ),
    data: (files) {
      if (files.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'ATTACHED MATERIALS',
            icon: Icons.description_outlined,
            count: files.length,
          ),
          ...files.map((file) {
            final mbSize = (file.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
            final isPdf = file.title.toLowerCase().endsWith('.pdf');
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf
                          : Icons.insert_drive_file_outlined,
                      color: isPdf
                          ? const Color(0xFFC62828)
                          : const Color(0xFF1565C0),
                      size: 22.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: InkWell(
                      onTap: () => _run(context, () async {
                        if (!details.canManage &&
                            details.scope.lessonId != null &&
                            {
                              'pdf',
                              'txt',
                            }.contains(materialExtension(file.path))) {
                          await context.pushNamed(
                            AppRoute.lessonReading.name,
                            queryParameters: {
                              'lessonId': details.scope.lessonId!,
                              'materialId': file.id,
                            },
                          );
                          return;
                        }
                        final url = await ref.read(
                          curriculumMaterialUrlProvider(file).future,
                        );
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          throw StateError('Viewer unavailable');
                        }
                      }),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.title,
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$mbSize MB • Tap to preview',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (details.canManage)
                    IconButton(
                      tooltip: 'Delete material',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () => _run(
                        context,
                        () => ref
                            .read(
                              curriculumActionsProvider(details.scope).notifier,
                            )
                            .delete(file),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Open in viewer',
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: AppColors.grey600,
                      ),
                      onPressed: () => _run(context, () async {
                        if (!details.canManage &&
                            details.scope.lessonId != null &&
                            {
                              'pdf',
                              'txt',
                            }.contains(materialExtension(file.path))) {
                          await context.pushNamed(
                            AppRoute.lessonReading.name,
                            queryParameters: {
                              'lessonId': details.scope.lessonId!,
                              'materialId': file.id,
                            },
                          );
                          return;
                        }
                        final url = await ref.read(
                          curriculumMaterialUrlProvider(file).future,
                        );
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }),
                    ),
                ],
              ),
            );
          }),
          SizedBox(height: 12.h),
        ],
      );
    },
  );
}
