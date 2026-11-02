part of '../pages/teacher_lesson_media_screen.dart';

extension _LessonStudioHandoutsTab on _TeacherLessonMediaScreenState {
  Widget _buildMaterialUploadCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 40.w,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Upload Lecture Handouts',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 16.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'PDFs, presentations, slides, and study notes up to 50 MB.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey500,
            ),
          ),
          SizedBox(height: 20.h),
          FilledButton.icon(
            onPressed: busy.value ? null : _pickMaterial,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Upload handouts'),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoutsTab(AsyncValue<List<CurriculumMaterial>> materials) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          materials.when(
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30.h),
                child: const CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => Column(
              children: [
                _buildMaterialUploadCard(),
                const _AttachedEmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to load handouts',
                ),
              ],
            ),
            data: (files) {
              if (files.isEmpty) {
                return _buildMaterialUploadCard();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttachedHeader(
                    title: 'ATTACHED DOCUMENTS',
                    onRetry: () =>
                        ref.invalidate(curriculumMaterialsProvider(_scope)),
                  ),
                  SizedBox(height: 10.h),
                  ...files.map((file) {
                    final mb = (file.sizeBytes / (1024 * 1024)).toStringAsFixed(
                      1,
                    );
                    final isPdf = file.title.toLowerCase().endsWith('.pdf');
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.grey200),
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
                              onTap: () => _run(() async {
                                final url = await ref.read(
                                  curriculumMaterialUrlProvider(file).future,
                                );
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
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
                                    '$mb MB • Tap to preview',
                                    style: AppTextStyles.interRegular14
                                        .copyWith(
                                          fontSize: 11.sp,
                                          color: AppColors.grey500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete handout',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () => _run(
                              () => ref
                                  .read(
                                    curriculumActionsProvider(_scope).notifier,
                                  )
                                  .delete(file),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  _compactAddAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add another handout',
                    onPressed: busy.value ? null : _pickMaterial,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: ASSESSMENTS (QUIZZES & ASSIGNMENTS)
  // -------------------------------------------------------------
}
