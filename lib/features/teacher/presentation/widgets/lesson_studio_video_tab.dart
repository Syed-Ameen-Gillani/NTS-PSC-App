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
                  onPressed: busy.value
                      ? null
                      : () => ref.invalidate(
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
              final hasCurrentVideo = items.any((item) => item.isCurrent);
              final statusItem = items.firstWhere(
                (item) => item.error != null,
                orElse: () => items.firstWhere(
                  (item) => !item.isCurrent,
                  orElse: () => items.first,
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttachedHeader(
                    title: 'ATTACHED VIDEO',
                    trailing: AbsorbPointer(
                      absorbing: busy.value,
                      child: _videoHeaderActions(items.first),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ValueListenableBuilder(
                    valueListenable: progress,
                    builder: (context, value, _) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: value == null
                          ? _buildVideoStatus(statusItem, hasCurrentVideo)
                          : _buildVideoPreparationCard(
                              value,
                              isReplacement: hasCurrentVideo,
                            ),
                    ),
                  ),
                  ...items.map(
                    (item) => AbsorbPointer(
                      absorbing: busy.value,
                      child: _buildMediaCard(item),
                    ),
                  ),
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

  Widget _buildVideoPreparationCard(
    LessonUploadProgressValue value, {
    bool isReplacement = false,
  }) => Container(
    key: const ValueKey('video-preparation-card'),
    constraints: BoxConstraints(maxWidth: 350.w),
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 6.w, 10.h),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      border: Border(
        bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonUploadProgressDetails(
          value: value,
          showCancel:
              !_videoCancellationRequested &&
              (_uploadCancellation != null || _preparationCancellation != null),
          onCancel:
              _uploadCancellation == null &&
                  (_preparationCancellation == null ||
                      _preparationCancellation!.isCancelled)
              ? null
              : _confirmAndCancelVideoTransfer,
        ),
        if (isReplacement && value.label != 'Cancelling…') ...[
          SizedBox(height: 8.h),
          Text(
            'The current video stays live until this replacement is ready and published.',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 11.sp,
              height: 1.35,
              color: AppColors.grey600,
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _confirmAndCancelVideoTransfer() async {
    final token = _preparationCancellation;
    final uploadCancellation = _uploadCancellation;
    if (_cancelDialogOpen ||
        _videoCancellationRequested ||
        (uploadCancellation == null && (token == null || token.isCancelled))) {
      return;
    }
    _cancelDialogOpen = true;
    try {
      final confirmed = await confirmVideoPreparationCancellation(
        context,
        uploading: uploadCancellation != null,
      );
      if (!confirmed || !mounted || progress.value == null) {
        return;
      }
      Future<void> Function()? cancel;
      if (uploadCancellation != null &&
          identical(uploadCancellation, _uploadCancellation)) {
        cancel = uploadCancellation;
      } else if (token != null &&
          identical(token, _preparationCancellation) &&
          !token.isCancelled) {
        cancel = token.cancel;
      }
      if (cancel == null) return;
      _videoCancellationRequested = true;
      progress.value = progress.value!.copyWith(label: 'Cancelling…');
      try {
        await cancel();
      } catch (error, stackTrace) {
        developer.log(
          'Video cancellation did not finish cleanly.',
          name: 'CBOA.VideoUpload',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      _cancelDialogOpen = false;
    }
  }

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
          if (isTranscribing && item.error == null)
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

  Widget _buildVideoStatus(LessonMedia item, bool hasCurrentVideo) {
    final isReplacement = hasCurrentVideo && !item.isCurrent;
    final (title, message, icon, color) = item.error != null
        ? (
            'TRANSCRIPTION FAILED',
            'Retry or review the transcript below.',
            Icons.error_outline_rounded,
            AppColors.error,
          )
        : switch (item.status) {
            'uploading' => (
              isReplacement ? 'REPLACEMENT UPLOADING' : 'VIDEO UPLOADING',
              'Keep this screen open while the upload finishes.',
              Icons.cloud_upload_outlined,
              AppColors.primary,
            ),
            'transcribing' => (
              isReplacement ? 'REPLACEMENT PROCESSING' : 'VIDEO PROCESSING',
              isReplacement
                  ? 'Creating the transcript. The current video remains live.'
                  : 'Creating the transcript for review.',
              Icons.auto_awesome_outlined,
              AppColors.primary,
            ),
            'needs_review' => (
              isReplacement ? 'REPLACEMENT NEEDS REVIEW' : 'TRANSCRIPT REVIEW',
              isReplacement
                  ? 'Review the transcript, then publish this replacement.'
                  : 'Review the transcript before publishing the video.',
              Icons.fact_check_outlined,
              AppColors.accent,
            ),
            'ready' when item.isCurrent => (
              'LIVE FOR STUDENTS',
              'This is the video currently available to learners.',
              Icons.check_circle_outline_rounded,
              AppColors.success,
            ),
            'ready' => (
              'REPLACEMENT READY',
              'Publish the course changes to make this video live for students.',
              Icons.task_alt_rounded,
              AppColors.primary,
            ),
            _ => (
              'VIDEO STATUS',
              'This video is being prepared.',
              Icons.info_outline_rounded,
              AppColors.primary,
            ),
          };

    return _VideoStatusAnnouncement(
      key: ValueKey(
        'video-status-${item.id}-${item.status}-${item.isCurrent}-${item.error}',
      ),
      title: title,
      message: message,
      icon: icon,
      color: color,
    );
  }

  Widget _videoHeaderActions(LessonMedia item) {
    final disabled = busy.value || item.status == 'uploading';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
