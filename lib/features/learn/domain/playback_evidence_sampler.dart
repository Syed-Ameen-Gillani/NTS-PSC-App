/// Samples contiguous foreground playback. Seeking, buffering, speed changes,
/// long timer stalls and time spent away never contribute skipped coverage.
class PlaybackEvidenceSampler {
  int? _position;
  int? _clock;
  bool _playing = false;
  double _speed = 1;

  ({int start, int end, int wallMs, double speed})? sample({
    required int positionMs,
    required int clockMs,
    required bool playing,
    required bool buffering,
    required bool active,
    required double speed,
  }) {
    final before = _position;
    final elapsed = _clock == null ? 0 : clockMs - _clock!;
    final delta = before == null ? 0 : positionMs - before;
    // Native position notifications can arrive more slowly than our polling
    // timer. Retain the last moving baseline through repeated positions so
    // the next update is measured over its full elapsed playback time.
    if (delta == 0 &&
        before != null &&
        active &&
        playing &&
        !buffering &&
        _playing &&
        speed == _speed &&
        elapsed >= 0 &&
        elapsed < 10000) {
      return null;
    }
    final valid =
        active &&
        !buffering &&
        _playing &&
        speed == _speed &&
        elapsed > 0 &&
        elapsed <= 10000 &&
        delta > 0 &&
        delta <= elapsed * speed + 200 &&
        delta >= elapsed * speed * .5;
    _position = positionMs;
    _clock = clockMs;
    _playing = active && playing && !buffering;
    _speed = speed;
    return valid
        ? (start: before!, end: positionMs, wallMs: elapsed, speed: speed)
        : null;
  }

  void reset() {
    _position = null;
    _clock = null;
    _playing = false;
  }
}
