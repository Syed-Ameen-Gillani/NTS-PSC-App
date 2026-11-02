import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/core/utils/content_text_direction.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_controls_state.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_study_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_search_bar.dart';

typedef _Editor = ({
  String query,
  bool editing,
  String? id,
  int seconds,
  bool saving,
});
final _editor = StateProvider.autoDispose.family<_Editor, Object>(
  (ref, key) =>
      (query: '', editing: false, id: null, seconds: 0, saving: false),
);

List<({double start, double end, String text})> searchableTranscript(
  List<Map<String, dynamic>> segments,
  String query,
) {
  final result = <({double start, double end, String text})>[];
  final term = query.trim().toLowerCase();
  for (final segment in segments) {
    final start = segment['start'];
    final end = segment['end'];
    final text = segment['text'];
    if (start is num &&
        end is num &&
        start.isFinite &&
        end.isFinite &&
        start >= 0 &&
        end > start &&
        text is String &&
        text.trim().isNotEmpty &&
        text.toLowerCase().contains(term)) {
      result.add((start: start.toDouble(), end: end.toDouble(), text: text));
    }
  }
  return result;
}

class VideoStudyPanel extends ConsumerStatefulWidget {
  const VideoStudyPanel({
    super.key,
    required this.controller,
    required this.scope,
    this.segments = const [],
  });
  final VideoPlayerController controller;
  final VideoStudyKey scope;
  final List<Map<String, dynamic>> segments;
  @override
  ConsumerState<VideoStudyPanel> createState() => _VideoStudyPanelState();
}

class _VideoStudyPanelState extends ConsumerState<VideoStudyPanel> {
  final _identity = Object();
  final _text = TextEditingController();
  final _query = TextEditingController();
  _Editor get editor => ref.read(_editor(_identity));
  void update(_Editor value) =>
      ref.read(_editor(_identity).notifier).state = value;

  Future<void> _seek(double seconds) async {
    try {
      await widget.controller.seekTo(
        boundedVideoSeek(
          Duration(milliseconds: (seconds * 1000).round()),
          widget.controller.value.duration,
        ),
      );
    } catch (_) {
      _error('Could not seek. Please retry.');
    }
  }

  void _error(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _edit([VideoStudyNote? note]) {
    if (editor.saving) return;
    widget.controller.pause();
    _text.text = note?.text ?? '';
    update((
      query: editor.query,
      editing: true,
      id: note?.id,
      seconds: note?.seconds ?? widget.controller.value.position.inSeconds,
      saving: false,
    ));
  }

  Future<void> _save() async {
    final current = editor;
    if (current.saving) return;
    if (_text.text.trim().isEmpty) {
      _error('Write a note first.');
      return;
    }
    update((
      query: current.query,
      editing: true,
      id: current.id,
      seconds: current.seconds,
      saving: true,
    ));
    try {
      await ref
          .read(videoStudyProvider(widget.scope).notifier)
          .saveNote(id: current.id, seconds: current.seconds, text: _text.text);
      if (!mounted) return;
      _text.clear();
      update((
        query: editor.query,
        editing: false,
        id: null,
        seconds: 0,
        saving: false,
      ));
    } catch (_) {
      if (!mounted) return;
      update((
        query: current.query,
        editing: true,
        id: current.id,
        seconds: current.seconds,
        saving: false,
      ));
      _error('Could not save note. Please retry.');
    }
  }

  Future<void> _delete(VideoStudyNote note) async {
    try {
      await ref
          .read(videoStudyProvider(widget.scope).notifier)
          .removeNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (!mounted) return;
              try {
                await ref
                    .read(videoStudyProvider(widget.scope).notifier)
                    .saveNote(
                      id: note.id,
                      seconds: note.seconds,
                      text: note.text,
                    );
              } catch (_) {
                _error('Could not restore note. Please retry.');
              }
            },
          ),
        ),
      );
    } catch (_) {
      _error('Could not delete note. Please retry.');
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = ref.watch(_editor(_identity));
    final notes =
        ref.watch(videoStudyProvider(widget.scope)).value?.notes ?? [];
    final segments = searchableTranscript(widget.segments, current.query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.segments.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
            title: Text(
              'Transcript',
              style: AppTextStyles.interSemiBold16.copyWith(
                color: colors.onSurface,
              ),
            ),
            childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            children: [
              AppSearchField(
                controller: _query,
                hintText: 'Search transcript',
                onChanged: (text) => update((
                  query: text,
                  editing: current.editing,
                  id: current.id,
                  seconds: current.seconds,
                  saving: current.saving,
                )),
              ),
              if (segments.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const Text('No matching transcript'),
                )
              else
                SizedBox(
                  height: 240.h.clamp(160, 320),
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: widget.controller,
                    builder: (_, value, _) => ListView.builder(
                      itemCount: segments.length,
                      itemBuilder: (_, index) {
                        final item = segments[index];
                        final second = value.position.inMilliseconds / 1000;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          selected: second >= item.start && second < item.end,
                          selectedTileColor: colors.surfaceContainerHighest,
                          leading: Text(
                            videoTime(Duration(seconds: item.start.floor())),
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 12.sp,
                              color: colors.primary,
                            ),
                          ),
                          title: Text(
                            item.text,
                            textDirection: contentTextDirection(item.text),
                            textAlign:
                                contentTextDirection(item.text) ==
                                    TextDirection.rtl
                                ? TextAlign.right
                                : TextAlign.left,
                            style: AppTextStyles.interRegular14.copyWith(
                              height: 1.5,
                              color: colors.onSurface,
                            ),
                          ),
                          onTap: () => _seek(item.start),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ExpansionTile(
          title: const Text('My notes'),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: current.saving || current.editing ? null : _edit,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add note'),
              ),
            ),
            if (current.editing) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(videoTime(Duration(seconds: current.seconds))),
              ),
              SizedBox(height: 8.h),
              TextField(
                onTapOutside: dismissKeyboardOnTapOutside,
                controller: _text,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                readOnly: current.saving,
                decoration: const InputDecoration(hintText: 'Your note'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Cancel note',
                    icon: const Icon(Icons.close),
                    onPressed: current.saving
                        ? null
                        : () => update((
                            query: current.query,
                            editing: false,
                            id: null,
                            seconds: 0,
                            saving: false,
                          )),
                  ),
                  IconButton(
                    tooltip: 'Save note',
                    onPressed: current.saving ? null : _save,
                    icon: current.saving
                        ? SizedBox.square(
                            dimension: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ),
            ],
            if (notes.isEmpty && !current.editing)
              Padding(
                padding: EdgeInsets.all(16.r),
                child: const Text('No notes yet'),
              ),
            for (final note in notes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(videoTime(Duration(seconds: note.seconds))),
                title: Text(note.text),
                onTap: () => _seek(note.seconds.toDouble()),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Note options',
                  enabled: !current.saving,
                  onSelected: (action) =>
                      action == 'edit' ? _edit(note) : _delete(note),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
