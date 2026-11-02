import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/data/lesson_reading_repository.dart';
import 'package:nts_psc_app/features/learn/data/offline_reading_store.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final _readingPage = StateProvider.autoDispose.family<int, ReadingKey>(
  (ref, key) => 0,
);

class LessonReadingScreen extends ConsumerWidget {
  const LessonReadingScreen({
    super.key,
    required this.reading,
    this.title,
    this.offlineOnly = false,
  });
  final ReadingKey reading;
  final String? title;
  final bool offlineOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentState = offlineOnly
        ? ref.watch(savedLessonReadingProvider(reading))
        : ref.watch(lessonReadingProvider(reading));
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        actions: [
          if (documentState.value case final document? when !document.isOffline)
            IconButton(
              tooltip: 'Save reading offline',
              icon: const Icon(Icons.download_outlined),
              onPressed: () async {
                try {
                  await ref
                      .read(offlineReadingStoreProvider)
                      .save(
                        owner: document.owner,
                        lessonId: reading.lessonId,
                        materialId: reading.materialId,
                        ticket: document.ticket,
                        text: document.text,
                        title: title ?? 'Lesson reading',
                        pdfUrl: document.pdfUrl,
                      );
                  if (context.mounted) {
                    ref.invalidate(offlineReadingsProvider);
                    CustomToast.showInfo(
                      context,
                      message: 'Reading saved offline',
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    CustomToast.showError(
                      context,
                      message: 'Could not save reading',
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: documentState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not open this reading.'),
              TextButton(
                onPressed: () => ref.invalidate(
                  offlineOnly
                      ? savedLessonReadingProvider(reading)
                      : lessonReadingProvider(reading),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (document) => _ReadingView(
          key: ValueKey(document.ticket['id']),
          reading: reading,
          document: document,
          onRetry: () => ref.invalidate(
            offlineOnly
                ? savedLessonReadingProvider(reading)
                : lessonReadingProvider(reading),
          ),
        ),
      ),
    );
  }
}

class _ReadingView extends ConsumerStatefulWidget {
  const _ReadingView({
    super.key,
    required this.reading,
    required this.document,
    required this.onRetry,
  });
  final ReadingKey reading;
  final ReadingDocument document;
  final VoidCallback onRetry;
  @override
  ConsumerState<_ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends ConsumerState<_ReadingView>
    with WidgetsBindingObserver {
  late final LearningEvidenceRepository repository;
  final clock = Stopwatch();
  final pages = PageController();
  Timer? timer;
  bool foreground = true;
  bool ready = false;
  bool covered = false;
  bool busy = false;
  bool materialCompletionRequested = false;
  int previousMs = 0;
  int lastPage = -1;
  int ticks = 0;

  @override
  void initState() {
    super.initState();
    repository = ref.read(learningEvidenceRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    ready = widget.document.pdfUrl == null && widget.document.pdfPath == null;
    developer.log(
      'Reader mounted: lesson=${widget.reading.lessonId}, '
      'material=${widget.reading.materialId ?? 'lesson-notes'}, '
      'remotePdf=${widget.document.pdfUrl != null}, '
      'localPdf=${widget.document.pdfPath != null}, '
      'expectedUnits=${widget.document.ticket['units']}.',
      name: 'CBOA.Reading',
    );
    clock.start();
    if (ready) {
      timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(tick()),
      );
    }
  }

  Future<void> tick() async {
    final now = clock.elapsedMilliseconds;
    final elapsed = now - previousMs;
    previousMs = now;
    final page = ref.read(_readingPage(widget.reading));
    final stable = page == lastPage;
    lastPage = page;
    if (busy ||
        !ready ||
        !covered ||
        !stable ||
        !foreground ||
        elapsed > 2000 ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    busy = true;
    try {
      await repository.append(
        widget.document.owner,
        widget.document.ticket,
        start: page,
        end: page + 1,
        wallMs: elapsed,
      );
      if (++ticks % 5 == 0) {
        await repository.sync();
        if (mounted) {
          ref.invalidate(learningOutcomeProvider(widget.reading.lessonId));
        }
      }
    } catch (_) {
      // Keep the reader usable; unsynced evidence is never completed locally.
    } finally {
      busy = false;
    }
  }

  Future<void> completeOpenedMaterial() async {
    if (materialCompletionRequested || widget.reading.materialId == null) {
      return;
    }
    final activity = widget.document.ticket['activity_id'] as String?;
    if (activity == null) return;
    materialCompletionRequested = true;
    developer.log(
      'Confirming successful handout open: activity=$activity.',
      name: 'CBOA.Reading',
    );
    try {
      await repository.recordMaterialOpened(
        widget.document.owner,
        widget.document.ticket,
      );
      developer.log(
        'Handout open saved for server confirmation.',
        name: 'CBOA.Reading',
      );
      if (mounted) {
        ref.invalidate(learningOutcomeProvider(widget.reading.lessonId));
      }
    } catch (error, stackTrace) {
      materialCompletionRequested = false;
      developer.log(
        'Could not confirm the opened handout.',
        name: 'CBOA.LearningProgress',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    lastPage = -1;
    previousMs = clock.elapsedMilliseconds;
    if (!foreground) unawaited(repository.sync());
  }

  @override
  void dispose() {
    developer.log(
      'Reader disposed: ready=$ready, '
      'completionRequested=$materialCompletionRequested.',
      name: 'CBOA.Reading',
    );
    timer?.cancel();
    pages.dispose();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(repository.sync());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(_readingPage(widget.reading));
    final document = widget.document;
    final count = (document.ticket['units'] as num).toInt();
    final isPdf = document.pdfUrl != null || document.pdfPath != null;
    final pdfParams = PdfViewerParams(
      onDocumentLoadFinished: (_, succeeded) {
        if (!succeeded) {
          ready = false;
          covered = false;
          developer.log(
            'PDF loading failed before viewer readiness.',
            name: 'CBOA.Reading',
          );
        }
      },
      errorBannerBuilder: (context, error, stackTrace, _) {
        developer.log(
          'PDF viewer failure: type=${error.runtimeType}.',
          name: 'CBOA.Reading',
          stackTrace: stackTrace,
        );
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not open this PDF. Try again.'),
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        );
      },
      onViewerReady: (pdf, controller) {
        ready = pdf.pages.length == count;
        covered = ready;
        developer.log(
          'PDF viewer ready: actualPages=${pdf.pages.length}, '
          'expectedPages=$count, accepted=$ready.',
          name: 'CBOA.Reading',
        );
        if (ready) unawaited(completeOpenedMaterial());
      },
      onPageChanged: (value) {
        if (value != null && mounted) {
          ref.read(_readingPage(widget.reading).notifier).state = value - 1;
        }
      },
    );
    return Column(
      children: [
        if (document.isOffline)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: const Text('Saved reading · Progress syncs when online'),
          ),
        Expanded(
          child: isPdf
              ? document.pdfPath != null
                    ? PdfViewer.file(document.pdfPath!, params: pdfParams)
                    : PdfViewer.uri(
                        Uri.parse(document.pdfUrl!),
                        params: pdfParams,
                      )
              : PageView.builder(
                  controller: pages,
                  itemCount: document.pages.length,
                  onPageChanged: (value) {
                    covered = false;
                    ref.read(_readingPage(widget.reading).notifier).state =
                        value;
                  },
                  itemBuilder: (context, index) => LayoutBuilder(
                    builder: (context, constraints) =>
                        NotificationListener<ScrollNotification>(
                          onNotification: (event) {
                            if (index == page &&
                                event.metrics.extentAfter <= 8.h) {
                              covered = true;
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: LayoutBuilder(
                                builder: (context, _) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && index == page) {
                                      final painter =
                                          TextPainter(
                                            text: TextSpan(
                                              text: document.pages[index],
                                              style:
                                                  AppTextStyles.interRegular14,
                                            ),
                                            textDirection: Directionality.of(
                                              context,
                                            ),
                                            textScaler: MediaQuery.textScalerOf(
                                              context,
                                            ),
                                          )..layout(
                                            maxWidth:
                                                constraints.maxWidth - 40.w,
                                          );
                                      if (painter.height + 40.w <=
                                          constraints.maxHeight) {
                                        covered = true;
                                      }
                                    }
                                  });
                                  return SelectableText(
                                    document.pages[index],
                                    style: AppTextStyles.interRegular14,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
        ),
        if (!isPdf)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: page > 0
                    ? () => pages.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      )
                    : null,
                child: const Text('Previous'),
              ),
              Text('${page + 1} / $count'),
              TextButton(
                onPressed: page + 1 < count
                    ? () => pages.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      )
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
      ],
    );
  }
}
