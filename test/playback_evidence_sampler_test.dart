import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/domain/playback_evidence_sampler.dart';

void main() {
  for (final updateMs in [500, 1000]) {
    test(
      'credits playback when native positions update every $updateMs ms',
      () {
        final sampler = PlaybackEvidenceSampler();
        var covered = 0;
        for (var clock = 0; clock <= 10000; clock += 250) {
          final evidence = sampler.sample(
            positionMs: clock ~/ updateMs * updateMs,
            clockMs: clock,
            playing: true,
            buffering: false,
            active: true,
            speed: 1,
          );
          if (evidence != null) covered += evidence.end - evidence.start;
        }
        expect(covered, 10000);
      },
    );
  }

  test('credits contiguous playback and excludes seek gaps', () {
    final s = PlaybackEvidenceSampler();
    Object? tick(
      int position,
      int clock, {
      bool playing = true,
      bool buffering = false,
      bool active = true,
      double speed = 1,
    }) => s.sample(
      positionMs: position,
      clockMs: clock,
      playing: playing,
      buffering: buffering,
      active: active,
      speed: speed,
    );
    expect(tick(0, 0), isNull);
    expect(tick(1000, 1000), isNotNull);
    expect(tick(90000, 2000), isNull);
    expect(tick(91000, 3000), isNotNull);
    expect(tick(92000, 4000, active: false), isNull);
    expect(tick(93000, 5000), isNull);
    expect(tick(94000, 6000), isNotNull);
    expect(tick(95000, 7000, buffering: true), isNull);
    expect(tick(96000, 8000), isNull);
    expect(
      tick(97000, 9000, playing: false),
      isNotNull,
    ); // Final played interval.
    expect(tick(97000, 10000, playing: false), isNull);
  });
  test('repeated positions do not credit buffering or an eventual seek', () {
    final sampler = PlaybackEvidenceSampler();
    Object? tick(int position, int clock, {bool buffering = false}) =>
        sampler.sample(
          positionMs: position,
          clockMs: clock,
          playing: true,
          buffering: buffering,
          active: true,
          speed: 1,
        );
    expect(tick(0, 0), isNull);
    expect(tick(0, 250), isNull);
    expect(tick(0, 500, buffering: true), isNull);
    expect(tick(500, 1000), isNull);
    expect(tick(1000, 1500), isNotNull);
    expect(tick(1000, 1750), isNull);
    expect(tick(60000, 2000), isNull);
    expect(tick(60500, 2500), isNotNull);
  });
  test('rate changes reset baseline, subsequent 2x playback is credited', () {
    final s = PlaybackEvidenceSampler();
    s.sample(
      positionMs: 0,
      clockMs: 0,
      playing: true,
      buffering: false,
      active: true,
      speed: 1,
    );
    expect(
      s.sample(
        positionMs: 1000,
        clockMs: 1000,
        playing: true,
        buffering: false,
        active: true,
        speed: 2,
      ),
      isNull,
    );
    final sample = s.sample(
      positionMs: 3000,
      clockMs: 2000,
      playing: true,
      buffering: false,
      active: true,
      speed: 2,
    );
    expect(sample?.wallMs, 1000);
    expect(sample?.end, 3000);
    expect(
      s.sample(
        positionMs: 13000,
        clockMs: 7000,
        playing: true,
        buffering: false,
        active: true,
        speed: 2,
      ),
      isNotNull,
    );
    expect(
      s.sample(
        positionMs: 43000,
        clockMs: 22000,
        playing: true,
        buffering: false,
        active: true,
        speed: 2,
      ),
      isNull,
    );
  });
}
