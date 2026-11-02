import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_compress/flutter_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_lesson_media_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_transcript_editor.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_checkpoint_review.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_video_preview.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_upload_progress.dart';

part '../widgets/lesson_studio_video_tab.dart';
part '../widgets/lesson_studio_handouts_tab.dart';
part '../widgets/lesson_studio_assessments_tab.dart';
part '../widgets/lesson_studio_shared_widgets.dart';

class TeacherLessonMediaScreen extends ConsumerStatefulWidget {
  const TeacherLessonMediaScreen({super.key, required this.lesson});
  final LessonModel lesson;

  @override
  ConsumerState<TeacherLessonMediaScreen> createState() =>
      _TeacherLessonMediaScreenState();
}

class _TeacherLessonMediaScreenState
    extends ConsumerState<TeacherLessonMediaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final busy = ValueNotifier<bool>(false);
  final progress = ValueNotifier<LessonUploadProgressValue?>(null);
  CancellationToken? _preparationCancellation;
  Timer? _refresh;

  CurriculumScope get _scope => CurriculumScope(lessonId: widget.lesson.id);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || busy.value) return;
      final items = ref
          .read(teacherLessonMediaProvider(widget.lesson.id))
          .value;
      if (items?.any((item) => item.status == 'transcribing') ?? false) {
        ref.invalidate(teacherLessonMediaProvider(widget.lesson.id));
      }
    });
  }

  @override
  void dispose() {
    unawaited(_preparationCancellation?.cancel());
    _tabController.dispose();
    _refresh?.cancel();
    busy.dispose();
    progress.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await action();
      if (mounted) ref.invalidate(teacherLessonMediaProvider(widget.lesson.id));
    } on CompressCancelled {
      // Cancelling preparation is an intentional action, not an upload error.
    } catch (error) {
      if (mounted) {
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : error is PostgrestException
              ? error.message
              : 'Could not complete media action',
        );
      }
    } finally {
      _preparationCancellation = null;
      if (mounted) {
        ref.invalidate(teacherLessonMediaProvider(widget.lesson.id));
        progress.value = null;
        busy.value = false;
      }
    }
  }

  Future<void> _pickVideo() => _run(() async {
    try {
      developer.log(
        'Opening video picker for lesson ${widget.lesson.id}.',
        name: 'CBOA.VideoUpload',
      );
      final picked = await FilePicker.pickFile(type: FileType.video);
      if (picked == null) {
        developer.log(
          'Video picker was cancelled for lesson ${widget.lesson.id}.',
          name: 'CBOA.VideoUpload',
        );
        return;
      }
      if (!mounted) return;
      final path = picked.path;
      developer.log(
        'Video selected: name=${picked.name}, extension=${picked.extension}, '
        'path=${path ?? '<unavailable>'}.',
        name: 'CBOA.VideoUpload',
      );
      if (path == null) {
        throw StateError('This device did not provide a local file.');
      }
      final extension = picked.extension?.toLowerCase();
      final mime = switch (extension) {
        'mp4' => 'video/mp4',
        'webm' => 'video/webm',
        'mov' => 'video/quicktime',
        _ => '',
      };
      final localFile = File(path);
      final sourceBytes = await localFile.length();
      developer.log(
        'Selected video metadata: mime=$mime, '
        'bytes=$sourceBytes, exists=${await localFile.exists()}.',
        name: 'CBOA.VideoUpload',
      );
      progress.value = LessonUploadProgressValue(
        label: 'Preparing video',
        value: 0,
        originalBytes: sourceBytes,
      );
      _preparationCancellation = CancellationToken();
      await ref
          .read(lessonMediaRepositoryProvider)
          .uploadVideo(
            lessonId: widget.lesson.id,
            file: localFile,
            mimeType: mime,
            preparationCancellation: _preparationCancellation,
            onPreparationEstimate: (estimate) {
              if (mounted &&
                  !(_preparationCancellation?.isCancelled ?? false)) {
                progress.value = LessonUploadProgressValue(
                  label: 'Compressing video',
                  value: progress.value?.value ?? 0,
                  originalBytes: estimate.sourceBytes,
                  expectedBytes: estimate.expectedBytes,
                );
              }
            },
            onCompressionProgress: (value) {
              if (mounted &&
                  !(_preparationCancellation?.isCancelled ?? false)) {
                progress.value =
                    (progress.value ??
                            LessonUploadProgressValue(
                              label: 'Compressing video',
                              value: value,
                              originalBytes: sourceBytes,
                            ))
                        .copyWith(label: 'Compressing video', value: value);
              }
            },
            onProgress: (value) {
              _preparationCancellation = null;
              if (mounted) {
                progress.value =
                    (progress.value ??
                            LessonUploadProgressValue(
                              label: 'Uploading video',
                              value: value,
                              originalBytes: sourceBytes,
                            ))
                        .copyWith(label: 'Uploading video', value: value);
              }
            },
          );
      developer.log(
        'Video upload completed for lesson ${widget.lesson.id}.',
        name: 'CBOA.VideoUpload',
      );
    } on CompressCancelled {
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'Video upload failed for lesson ${widget.lesson.id}.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  });

  Future<void> _deleteVideo(LessonMedia item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text(
          'For a published course, learners keep the current video until you publish the change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete video'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final cleaned = await ref
          .read(lessonMediaRepositoryProvider)
          .deleteVideo(item.id);
      ref.invalidate(teacherControllerProvider);
      if (mounted) {
        CustomToast.showSuccess(
          context,
          message: cleaned
              ? 'Video change saved.'
              : 'Video removed. File cleanup will retry.',
        );
      }
    });
  }

  Future<CurriculumScope> _resolveScope() async {
    try {
      final contextRef = await ref.read(
        curriculumContextProvider(_scope).future,
      );
      return contextRef.scope;
    } catch (_) {
      return _scope;
    }
  }

  Future<void> _pickMaterial() => _run(() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: curriculumMimeTypes.keys.toList(),
    );
    if (!mounted || file == null) return;
    if (file.path == null) {
      throw ArgumentError('Choose a file saved on this device.');
    }
    final size = await File(file.path!).length();
    validateCurriculumMaterial(file.name, size);
    if (!mounted) return;
    final scope = await _resolveScope();
    await ref.read(curriculumActionsProvider(scope).notifier).upload([
      (path: file.path!, name: file.name, sizeBytes: size),
    ]);
    if (mounted) {
      CustomToast.showSuccess(context, message: 'Document attached to lesson.');
    }
  });

  Future<void> _linkAssessment(String kind) async {
    final contextRef = await ref.read(curriculumContextProvider(_scope).future);
    if (!mounted) return;
    final courseId = contextRef.scope.courseId;
    if (courseId == null) {
      CustomToast.showError(context, message: 'Course context unavailable.');
      return;
    }
    await context.pushNamed(
      AppRoute.teacherQuizStudio.name,
      extra: {
        'initialTab': kind == 'quiz' ? 0 : 1,
        'targetScope': contextRef.scope,
      },
    );
    if (!mounted) return;
    ref.invalidate(curriculumAssessmentsProvider(contextRef.scope));
    ref.invalidate(curriculumVisibleAssessmentsProvider(_scope));
  }

  Future<void> _openAssessment(CurriculumAssessment item) => _run(() async {
    if (item.kind == 'assignment') {
      await context.pushNamed(
        AppRoute.teacherReviewAssignment.name,
        queryParameters: {'assignmentId': item.assessmentId},
      );
    } else {
      final quiz = await ref.read(
        curriculumQuizProvider(item.assessmentId).future,
      );
      if (quiz == null || !mounted) return;
      if (!quiz.isPublished) {
        await context.pushNamed(AppRoute.teacherCreateQuiz.name, extra: quiz);
      } else {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.7,
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Text(quiz.title, style: Theme.of(ctx).textTheme.titleLarge),
                  for (final question in quiz.questions)
                    ListTile(title: Text(question.questionText)),
                ],
              ),
            ),
          ),
        );
      }
      final scope = await _resolveScope();
      ref.invalidate(curriculumAssessmentsProvider(scope));
    }
  });

  @override
  Widget build(BuildContext context) {
    final resolvedScope =
        ref.watch(curriculumContextProvider(_scope)).value?.scope ?? _scope;
    final media = ref.watch(teacherLessonMediaProvider(widget.lesson.id));
    final materials = ref.watch(curriculumMaterialsProvider(resolvedScope));
    final assessments = ref.watch(curriculumVisibleAssessmentsProvider(_scope));

    return ValueListenableBuilder<bool>(
      valueListenable: busy,
      builder: (context, isBusy, _) => PopScope(
        canPop: !isBusy,
        child: AppScaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Lesson Studio',
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 18.sp,
                color: AppColors.onBackground,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Learning requirements',
                onPressed: isBusy
                    ? null
                    : () => context.pushNamed(
                        AppRoute.teacherLessonActivities.name,
                        queryParameters: {'lessonId': widget.lesson.id},
                      ),
                icon: const Icon(Icons.tune_outlined),
              ),
            ],
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.onBackground,
                size: 20,
              ),
              onPressed: isBusy ? null : () => context.pop(),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(88.h),
              child: Column(
                children: [
                  // Lesson Details Pill Banner
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.lesson.title,
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 15.sp,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${widget.lesson.durationMinutes} min',
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Three Segmented Studio Tabs
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.grey600,
                      labelStyle: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 13.sp,
                      ),
                      unselectedLabelStyle: AppTextStyles.interMedium16
                          .copyWith(fontSize: 13.sp),
                      tabs: const [
                        Tab(text: 'Video'),
                        Tab(text: 'Handouts'),
                        Tab(text: 'Assessments'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(color: AppColors.grey200, height: 1.h),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: isBusy,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Video & Transcripts & Checkpoints
                  _buildVideoTab(media),

                  // Tab 2: Handouts & Documents
                  _buildHandoutsTab(materials),

                  // Tab 3: Quizzes & Assessments
                  _buildAssessmentsTab(assessments),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
