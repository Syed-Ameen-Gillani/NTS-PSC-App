import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/core/utils/content_text_direction.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final lessonTranscriptDirtyProvider = StateProvider.autoDispose
    .family<bool, String>((ref, id) => false);

class LessonTranscriptEditor extends ConsumerStatefulWidget {
  const LessonTranscriptEditor({
    super.key,
    required this.media,
    required this.lesson,
    required this.run,
  });
  final LessonMedia media;
  final LessonModel lesson;
  final Future<void> Function(Future<void> Function()) run;

  @override
  ConsumerState<LessonTranscriptEditor> createState() =>
      _LessonTranscriptEditorState();
}

class _LessonTranscriptEditorState
    extends ConsumerState<LessonTranscriptEditor> {
  final _form = GlobalKey<FormState>();
  late List<TextEditingController> _texts;
  late List<TextEditingController> _starts;
  late List<TextEditingController> _ends;
  bool get _dirty => ref.read(lessonTranscriptDirtyProvider(widget.media.id));
  void _markDirty() =>
      ref.read(lessonTranscriptDirtyProvider(widget.media.id).notifier).state =
          true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    final segments = widget.media.segments.isEmpty
        ? <Map<String, dynamic>>[
            {
              'start': 0,
              'end': (widget.lesson.durationMinutes * 60).clamp(
                1,
                double.maxFinite,
              ),
              'text': '',
            },
          ]
        : widget.media.segments;
    _texts = segments
        .map(
          (segment) =>
              TextEditingController(text: segment['text'] as String? ?? ''),
        )
        .toList();
    _starts = segments
        .map((segment) => TextEditingController(text: '${segment['start']}'))
        .toList();
    _ends = segments
        .map((segment) => TextEditingController(text: '${segment['end']}'))
        .toList();
  }

  @override
  void didUpdateWidget(covariant LessonTranscriptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.media.segments != widget.media.segments) {
      _disposeFields();
      _initialize();
    }
  }

  void _disposeFields() {
    for (final controller in [..._texts, ..._starts, ..._ends]) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final segments = <Map<String, dynamic>>[];
    num previousEnd = 0;
    for (var i = 0; i < _texts.length; i++) {
      final start = num.parse(_starts[i].text.trim());
      final end = num.parse(_ends[i].text.trim());
      if (end <= start || start < previousEnd) {
        CustomToast.showError(
          context,
          message: end <= start
              ? 'Segment ${i + 1}: end time must be after start time.'
              : 'Segment ${i + 1} overlaps segment $i.',
        );
        return;
      }
      previousEnd = end;
      segments.add({'start': start, 'end': end, 'text': _texts[i].text.trim()});
    }
    await widget.run(() async {
      await ref
          .read(lessonMediaRepositoryProvider)
          .saveTranscript(widget.media.id, segments, 'mixed');
      if (mounted) {
        ref
                .read(lessonTranscriptDirtyProvider(widget.media.id).notifier)
                .state =
            false;
      }
      if (mounted) {
        CustomToast.showSuccess(context, message: 'Transcript saved.');
      }
    });
  }

  String? _validateTime(String? value) {
    final time = num.tryParse(value?.trim() ?? '');
    return time == null || !time.isFinite || time < 0
        ? 'Enter valid seconds'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(lessonTranscriptDirtyProvider(widget.media.id));
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transcript',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 18.sp,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Text(
                '${_texts.length} segments',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Review the timing and correct the transcript before publishing.',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 18.h),
          for (var i = 0; i < _texts.length; i++) ...[
            Text(
              'Segment ${i + 1}',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 13.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    onTapOutside: dismissKeyboardOnTapOutside,
                    controller: _starts[i],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _markDirty(),
                    validator: _validateTime,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Start (seconds)',
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    onTapOutside: dismissKeyboardOnTapOutside,
                    controller: _ends[i],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _markDirty(),
                    validator: _validateTime,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'End (seconds)',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextFormField(
              onTapOutside: dismissKeyboardOnTapOutside,
              controller: _texts[i],
              textDirection: contentTextDirection(_texts[i].text),
              textAlign: contentTextDirection(_texts[i].text) == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
              onChanged: (_) => _markDirty(),
              minLines: 3,
              maxLines: 8,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter transcript text'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Transcript text',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 18.h),
            if (i + 1 < _texts.length) ...[
              Divider(color: colors.outlineVariant),
              SizedBox(height: 18.h),
            ],
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save transcript'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
