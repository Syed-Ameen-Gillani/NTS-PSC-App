import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';

final lessonCheckpointReviewProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) =>
          ref.read(lessonMediaRepositoryProvider).teacherCheckpoints(id),
    );

class LessonCheckpointReview extends ConsumerWidget {
  const LessonCheckpointReview({
    super.key,
    required this.mediaId,
    required this.run,
  });
  final String mediaId;
  final Future<void> Function(Future<void> Function()) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(lessonCheckpointReviewProvider(mediaId))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => TextButton(
          onPressed: () =>
              ref.invalidate(lessonCheckpointReviewProvider(mediaId)),
          child: const Text('Retry checks'),
        ),
        data: (checks) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'In-video checks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (checks.isEmpty) const Text('No checks generated yet.'),
            for (final check in checks)
              _CheckpointForm(
                key: ValueKey(check['id']),
                check: check,
                save: (changed, approved) => run(() async {
                  await ref
                      .read(lessonMediaRepositoryProvider)
                      .reviewCheckpoint(changed, approved: approved);
                  ref.invalidate(lessonCheckpointReviewProvider(mediaId));
                }),
              ),
          ],
        ),
      );
}

class _CheckpointForm extends StatefulWidget {
  const _CheckpointForm({super.key, required this.check, required this.save});
  final Map<String, dynamic> check;
  final Future<void> Function(Map<String, dynamic>, bool) save;
  @override
  State<_CheckpointForm> createState() => _CheckpointFormState();
}

class _CheckpointFormState extends State<_CheckpointForm> {
  final _form = GlobalKey<FormState>();
  late final _question = TextEditingController(
    text: widget.check['question'] as String,
  );
  late final _explanation = TextEditingController(
    text: widget.check['explanation'] as String? ?? '',
  );
  late final _options = (widget.check['options'] as List)
      .map((text) => TextEditingController(text: text as String))
      .toList();
  late final _optionFocus = List.generate(_options.length, (_) => FocusNode());
  final _explanationFocus = FocusNode();
  late final _correct = ValueNotifier<int>(
    widget.check['correct_index'] as int,
  );
  @override
  void dispose() {
    for (final controller in [_question, _explanation, ..._options]) {
      controller.dispose();
    }
    for (final focus in _optionFocus) {
      focus.dispose();
    }
    _explanationFocus.dispose();
    _correct.dispose();
    super.dispose();
  }

  Future<void> _save(bool approved) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await widget.save({
      ...widget.check,
      'question': _question.text.trim(),
      'explanation': _explanation.text.trim(),
      'options': _options.map((c) => c.text.trim()).toList(),
      'correct_index': _correct.value,
    }, approved);
  }

  String? _required(String? text) =>
      text == null || text.trim().isEmpty ? 'Enter text' : null;
  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      children: [
        SizedBox(height: 16.h),
        Text(
          'At ${widget.check['timestamp_seconds']} seconds | ${widget.check['status']}',
        ),
        TextFormField(
          onTapOutside: dismissKeyboardOnTapOutside,
          controller: _question,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              (_optionFocus.isEmpty ? _explanationFocus : _optionFocus.first)
                  .requestFocus(),
          validator: _required,
          decoration: const InputDecoration(labelText: 'Question'),
        ),
        for (var i = 0; i < _options.length; i++)
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: _correct,
                builder: (_, value, _) => IconButton(
                  tooltip: 'Correct answer ${i + 1}',
                  onPressed: () => _correct.value = i,
                  icon: Icon(
                    value == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  onTapOutside: dismissKeyboardOnTapOutside,
                  controller: _options[i],
                  focusNode: _optionFocus[i],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      (i < _optionFocus.length - 1
                              ? _optionFocus[i + 1]
                              : _explanationFocus)
                          .requestFocus(),
                  validator: _required,
                  decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                ),
              ),
            ],
          ),
        TextFormField(
          onTapOutside: dismissKeyboardOnTapOutside,
          controller: _explanation,
          focusNode: _explanationFocus,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Feedback'),
        ),
        Wrap(
          spacing: 8.w,
          children: [
            TextButton(
              onPressed: () => _save(false),
              child: const Text('Save check draft'),
            ),
            TextButton(
              onPressed: () => _save(true),
              child: const Text('Approve check'),
            ),
          ],
        ),
      ],
    ),
  );
}
