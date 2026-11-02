import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';

final videoStudyProvider = StateNotifierProvider.autoDispose
    .family<VideoStudyController, AsyncValue<VideoStudyState>, VideoStudyKey>(
      (ref, key) =>
          VideoStudyController(ref.read(videoStudyRepositoryProvider), key),
    );

class VideoStudyController extends StateNotifier<AsyncValue<VideoStudyState>> {
  VideoStudyController(this.repository, this.key)
    : super(const AsyncLoading()) {
    _load();
  }
  final VideoStudyRepository repository;
  final VideoStudyKey key;
  bool _alive = true;
  bool _savingNote = false;

  Future<void> _load() async {
    VideoStudyState value;
    try {
      value = await repository.read(key);
    } catch (_) {
      value = const VideoStudyState();
    }
    if (_alive) state = AsyncData(value);
  }

  Future<void> savePlayback(
    int positionMs,
    double speed,
    bool captions, {
    double volume = 1,
  }) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      positionMs: positionMs,
      speed: speed,
      captions: captions,
      volume: volume,
    );
    state = AsyncData(next);
    await repository.writePlayback(key, next);
  }

  Future<void> saveNote({
    String? id,
    required int seconds,
    required String text,
  }) async {
    final current = state.value;
    final trimmed = text.trim();
    if (current == null ||
        trimmed.isEmpty ||
        trimmed.length > 2000 ||
        seconds < 0) {
      throw ArgumentError('Enter a note of up to 2,000 characters.');
    }
    if (_savingNote) throw StateError('A note is already saving.');
    _savingNote = true;
    try {
      final note = VideoStudyNote(
        id: id ?? const Uuid().v4(),
        seconds: seconds,
        text: trimmed,
      );
      final notes = [...current.notes.where((item) => item.id != note.id), note]
        ..sort((a, b) => a.seconds.compareTo(b.seconds));
      // Persist first so a failed save leaves the editor and previous notes intact.
      final next = current.copyWith(notes: List.unmodifiable(notes));
      await repository.write(key, next);
      if (_alive) {
        final latest = state.value ?? current;
        state = AsyncData(latest.copyWith(notes: next.notes));
        try {
          await repository.writePlayback(key, state.requireValue);
        } catch (_) {
          // The note itself is already durable; resume state can retry later.
        }
      }
    } finally {
      _savingNote = false;
    }
  }

  Future<void> removeNote(String id) async {
    final current = state.value;
    if (current == null) return;
    if (_savingNote) throw StateError('A note is already saving.');
    _savingNote = true;
    final next = current.copyWith(
      notes: List.unmodifiable(current.notes.where((note) => note.id != id)),
    );
    try {
      await repository.write(key, next);
      if (_alive) {
        state = AsyncData((state.value ?? current).copyWith(notes: next.notes));
        try {
          await repository.writePlayback(key, state.requireValue);
        } catch (_) {
          // Deletion is durable even if a later playback metadata save fails.
        }
      }
    } finally {
      _savingNote = false;
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }
}
