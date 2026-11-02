part of '../pages/teacher_lesson_media_screen.dart';

extension _LessonStudioVideoTab on _TeacherLessonMediaScreenState {
  Widget _buildVideoTab(AsyncValue<List<LessonMedia>> media) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          media.when(
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: const CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => Column(
              children: [
                _buildVideoUploadCard(),
                TextButton(
                  onPressed: () => ref.invalidate(
                    teacherLessonMediaProvider(widget.lesson.id),
                  ),
                  child: const Text('Could not load video. Retry'),
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return _buildVideoUploadCard();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttachedHeader(
                    title: 'ATTACHED VIDEO',
                    trailing: _videoHeaderActions(items.first),
                  ),
                  SizedBox(height: 10.h),
                  ...items.map(_buildMediaCard),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.w,
                          color: AppColors.grey500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Only one video is allowed per lesson.',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: progress,
                    builder: (context, value, _) => value == null
                        ? const SizedBox.shrink()
                        : _buildVideoPreparationCard(value),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoUploadCard() => ValueListenableBuilder(
    valueListenable: progress,
    builder: (context, uploadProgress, _) => AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: uploadProgress == null
            ? _buildVideoPickerCard()
            : _buildVideoPreparationCard(uploadProgress),
      ),
    ),
  );

  Widget _buildVideoPickerCard() => Container(
    key: const ValueKey('video-picker-card'),
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
            Icons.videocam_outlined,
            size: 40.w,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Upload Lecture Video',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 16.sp,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Upload a lecture video to enable AI transcription and interactive checkpoints.',
          textAlign: TextAlign.center,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 13.sp,
            color: AppColors.grey500,
          ),
        ),
        SizedBox(height: 20.h),
        FilledButton.icon(
          onPressed: busy.value ? null : _pickVideo,
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Upload video'),
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

  Widget _buildVideoPreparationCard(LessonUploadProgressValue value) =>
      Container(
        key: const ValueKey('video-preparation-card'),
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: LessonUploadProgressDetails(
          value: value,
          showCancel: _preparationCancellation != null,
          onCancel:
              _preparationCancellation == null ||
                  _preparationCancellation!.isCancelled
              ? null
              : () async {
                  final token = _preparationCancellation;
                  if (token == null) return;
                  final cancelled = token.cancel();
                  progress.value = value.copyWith(label: 'Cancelling…');
                  try {
                    await cancelled;
                  } catch (_) {
                    // The latched token still prevents a later upload.
                  }
                },
        ),
      );

  Widget _buildMediaCard(LessonMedia item) {
    final isPublished = item.status == 'ready';
    final isNeedsReview = item.status == 'needs_review';
    final isTranscribing = item.status == 'transcribing';
    final isUploading = item.status == 'uploading';

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                'Transcription failed. Retry or review the transcript below.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          if (isTranscribing)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                'AI transcription is in progress.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
          if (!isUploading)
            TeacherVideoPreview(
              path: item.path,
              title: widget.lesson.title,
              segments: item.segments,
            ),
          if (!isPublished && !isUploading) ...[
            SizedBox(height: 16.h),
            Divider(color: AppColors.grey200),
          ],
          if (isNeedsReview && AppConfig.areLessonCheckpointsEnabled)
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generate checkpoints'),
              onPressed: () => _run(() async {
                await ref
                    .read(lessonMediaRepositoryProvider)
                    .generateCheckpoints(item.id);
                if (mounted) {
                  ref.invalidate(lessonCheckpointReviewProvider(item.id));
                }
              }),
            ),
          if (!isPublished && !isUploading)
            LessonTranscriptEditor(
              key: ValueKey(item.id),
              media: item,
              lesson: widget.lesson,
              run: _run,
            ),
          if (isNeedsReview && AppConfig.areLessonCheckpointsEnabled)
            LessonCheckpointReview(mediaId: item.id, run: _run),
          if (isNeedsReview)
            FilledButton.icon(
              icon: const Icon(Icons.publish_outlined),
              onPressed: ref.watch(lessonTranscriptDirtyProvider(item.id))
                  ? null
                  : () => _run(() async {
                      await ref
                          .read(lessonMediaRepositoryProvider)
                          .publish(item.id);
                      if (mounted) ref.invalidate(teacherControllerProvider);
                    }),
              label: const Text('Publish video'),
            ),
        ],
      ),
    );
  }

  Widget _videoHeaderActions(LessonMedia item) {
    final disabled = busy.value || item.status == 'uploading';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: disabled ? null : _pickVideo,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
          ),
          child: const Text('Change video'),
        ),
        IconButton(
          tooltip: 'Delete video',
          onPressed: disabled ? null : () => _deleteVideo(item),
          icon: Icon(Icons.delete_outline, size: 20.w),
          color: Theme.of(context).colorScheme.error,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: HANDOUTS & DOCUMENTS
  // -------------------------------------------------------------
}
