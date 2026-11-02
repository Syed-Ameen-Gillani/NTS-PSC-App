import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_evidence_store.dart';

final learningEvidenceRepositoryProvider = Provider(
  (ref) => LearningEvidenceRepository(Supabase.instance.client),
);

/// Durable, ordered evidence replay. Server decisions alone unlock lessons.
class LearningEvidenceRepository {
  LearningEvidenceRepository(this.client, {LearningEvidenceStore? store})
    : store = store ?? LearningEvidenceStore();
  final SupabaseClient client;
  final LearningEvidenceStore store;
  static final changes = StreamController<String>.broadcast();
  static const requestTimeout = Duration(seconds: 15);
  static const maxPending = 20000;
  String? get user => client.auth.currentUser?.id;

  /// Compare elapsed local time with the server-issued lifetime, rather than
  /// requiring the device clock to agree with the server's absolute date.
  static bool ticketIsCurrent(Map ticket, {DateTime? now}) {
    final cached = DateTime.tryParse(ticket['_cached_at'] as String? ?? '');
    final started = DateTime.tryParse(ticket['started_at'] as String? ?? '');
    final expires = DateTime.tryParse(ticket['expires_at'] as String? ?? '');
    if (cached == null || started == null || expires == null) return false;
    final lifetime = expires.difference(started);
    final elapsed = (now ?? DateTime.now()).toUtc().difference(cached.toUtc());
    return lifetime > Duration.zero &&
        lifetime <= const Duration(days: 7) &&
        elapsed >= Duration.zero &&
        elapsed < lifetime;
  }

  Future<Map<String, dynamic>> outcome(String lesson) async =>
      Map<String, dynamic>.from(
        await client
                .rpc('get_learning_outcome', params: {'p_lesson_id': lesson})
                .timeout(requestTimeout)
            as Map,
      );

  /// Completes a released handout after its PDF viewer opens successfully.
  /// Authorization, activity identity, and lesson access are revalidated by
  /// the database before any progress is written.
  Future<Map<String, dynamic>> confirmMaterialOpened(
    String lesson,
    String activity,
  ) async {
    final result = Map<String, dynamic>.from(
      await client
              .rpc(
                'confirm_learning_material_opened',
                params: {'p_lesson_id': lesson, 'p_activity_id': activity},
              )
              .timeout(requestTimeout)
          as Map,
    );
    if (result['activity_completed'] == true) changes.add(lesson);
    return result;
  }

  /// Persist a successful PDF open before attempting network confirmation.
  /// Repeated viewer callbacks share the same session entry.
  Future<void> recordMaterialOpened(
    String owner,
    Map<String, dynamic> ticket,
  ) async {
    if (user != owner || !ticketIsCurrent(ticket)) {
      throw StateError('Reconnect to confirm this handout.');
    }
    await store.transaction(owner, (data) async {
      if (user != owner) throw StateError('Account changed.');
      final pending =
          data.putIfAbsent('material_opens', () => <String, dynamic>{}) as Map;
      if (pending.length >= maxPending && !pending.containsKey(ticket['id'])) {
        throw StateError('Reconnect to sync your progress.');
      }
      pending[ticket['id']] = {
        'lesson_id': ticket['lesson_id'],
        'activity_id': ticket['activity_id'],
      };
    });
    await sync();
  }

  Future<void> _syncMaterialOpens(String owner) async {
    final pending = await store.read(
      owner,
      (data) async =>
          Map<String, dynamic>.from(data['material_opens'] as Map? ?? {}),
    );
    for (final entry in pending.entries) {
      if (user != owner) return;
      final lesson = (entry.value as Map)['lesson_id'] as String;
      try {
        final result =
            await client
                    .rpc(
                      'confirm_learning_material_session_opened',
                      params: {'p_session_id': entry.key},
                    )
                    .timeout(requestTimeout)
                as Map;
        if (user != owner) return;
        if (result['activity_completed'] != true) continue;
        await store.transaction(owner, (data) async {
          (data['material_opens'] as Map?)?.remove(entry.key);
          (data['errors'] as Map).remove(lesson);
        });
        changes.add(lesson);
      } on PostgrestException catch (error) {
        // Removed content, expired sessions and revoked access require a fresh
        // authorized open. Transport/server failures retain the durable event.
        if (!{'42501', '22023'}.contains(error.code)) rethrow;
        await store.transaction(owner, (data) async {
          (data['material_opens'] as Map?)?.remove(entry.key);
          (data['errors'] as Map)[lesson] =
              'Reopen this handout online to confirm progress.';
        });
      }
    }
  }

  Future<Map<String, dynamic>> session(
    String lesson,
    String activity, {
    String? expectedVersion,
  }) async {
    final owner = user;
    if (owner == null) throw StateError('Sign in to save progress.');
    final key = '$lesson:$activity';
    final cached = await store.read(owner, (data) async {
      final value = (data['tickets'] as Map)[key];
      return value is Map ? Map<String, dynamic>.from(value) : null;
    });
    if (cached != null &&
        ticketIsCurrent(cached) &&
        (expectedVersion == null ||
            cached['content_version'] == expectedVersion)) {
      return cached;
    }
    final ticket = Map<String, dynamic>.from(
      await client
              .rpc(
                'begin_learning_evidence',
                params: {'p_lesson_id': lesson, 'p_activity_id': activity},
              )
              .timeout(requestTimeout)
          as Map,
    );
    if (user != owner) throw StateError('Account changed.');
    if (expectedVersion != null &&
        ticket['content_version'] != expectedVersion) {
      throw StateError('This reading changed. Open it again.');
    }
    ticket['_cached_at'] = DateTime.now().toUtc().toIso8601String();
    await store.transaction(owner, (data) async {
      (data['tickets'] as Map)[key] = ticket;
      (data['errors'] as Map).remove(lesson);
    });
    return ticket;
  }

  Future<Map<String, dynamic>?> videoSession(
    String lesson, {
    String? source,
  }) async {
    // An already authorized ticket permits offline replay without new access.
    final owner = user;
    if (owner == null) return null;
    final cached = await store.read(
      owner,
      (data) async => (data['tickets'] as Map).values
          .whereType<Map>()
          .where(
            (t) =>
                t['lesson_id'] == lesson &&
                t['kind'] == 'video' &&
                (source == null || t['source'] == source) &&
                ticketIsCurrent(t),
          )
          .firstOrNull,
    );
    if (cached != null) return Map<String, dynamic>.from(cached);
    final state = await outcome(lesson);
    final activity = (state['activities'] as List)
        .cast<Map>()
        .where((a) => a['kind'] == 'video')
        .firstOrNull;
    if (activity == null) return null;
    if (source != null && activity['source'] != source) {
      throw StateError('This lesson changed. Reopen it to continue.');
    }
    return session(lesson, activity['id'] as String);
  }

  Future<void> append(
    String owner,
    Map<String, dynamic> ticket, {
    required int start,
    required int end,
    required int wallMs,
    double speed = 1,
  }) async {
    if (user != owner) return;
    await store.transaction(owner, (data) async {
      if (user != owner) return;
      final events = data['events'] as List;
      if (events.length >= maxPending) {
        throw StateError('Reconnect to sync your progress.');
      }
      final key = '${ticket['lesson_id']}:${ticket['activity_id']}';
      final current = (data['tickets'] as Map)[key] as Map?;
      if (current == null || current['id'] != ticket['id']) return;
      events.add({
        'session_id': current['id'],
        'sequence': current['next_sequence'],
        'start': start,
        'end': end,
        'wall_ms': wallMs,
        'speed': speed,
      });
      current['next_sequence'] = (current['next_sequence'] as num).toInt() + 1;
    });
  }

  static final _syncing = <String>{};

  Future<void> sync() async {
    final owner = user;
    if (owner == null || !_syncing.add(owner)) return;
    try {
      await _syncMaterialOpens(owner);
      // Lease a batch under the local lock, then release the file before I/O.
      // Playback can keep appending even while a slow network request is pending.
      for (var page = 0; page < maxPending ~/ 50 + 1 && user == owner; page++) {
        final batch = await store.read(
          owner,
          (data) async => (data['events'] as List)
              .take(50)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
        if (batch.isEmpty || user != owner) break;
        final results =
            await client
                    .rpc(
                      'record_learning_evidence',
                      params: {'p_events': batch},
                    )
                    .timeout(requestTimeout)
                as List;
        if (user != owner || results.length != batch.length) break;
        final changed = <String>{};
        await store.transaction(owner, (data) async {
          final events = data['events'] as List;
          // Appends only modify the tail; never acknowledge a different prefix.
          if (events.length < batch.length ||
              Iterable<int>.generate(batch.length).any(
                (i) =>
                    (events[i] as Map)['session_id'] !=
                        batch[i]['session_id'] ||
                    (events[i] as Map)['sequence'] != batch[i]['sequence'],
              )) {
            throw StateError('Progress queue changed. Retry syncing.');
          }
          final rejected = <String>{};
          final announced =
              data.putIfAbsent('announced', () => <String, dynamic>{}) as Map;
          for (var i = 0; i < results.length; i++) {
            final result = results[i] as Map;
            if (result['accepted'] != true) {
              developer.log(
                'Playback sample rejected: ${result['message']}',
                name: 'CBOA.LearningProgress',
              );
              final id = batch[i]['session_id'] as String;
              rejected.add(id);
              final tickets = data['tickets'] as Map;
              final keys = tickets.keys
                  .where((key) => (tickets[key] as Map)['id'] == id)
                  .toList();
              for (final key in keys) {
                (data['errors'] as Map)[key.toString().split(':').first] =
                    'Progress needs confirmation. Reopen this lesson online.';
                tickets.remove(key);
              }
            }
            final identity = result['lesson_completed'] == true
                ? 'lesson:${result['lesson_id']}'
                : 'activity:${batch[i]['session_id']}';
            if ((result['lesson_completed'] == true ||
                    result['activity_completed'] == true) &&
                announced[identity] != true) {
              announced[identity] = true;
              changed.add(result['lesson_id'] as String);
            }
          }
          events.removeRange(0, batch.length);
          final unconfirmed =
              data.putIfAbsent('unconfirmed', () => <dynamic>[]) as List;
          unconfirmed.addAll(
            batch.where((e) => rejected.contains(e['session_id'])),
          );
          unconfirmed.addAll(
            events.where((e) => rejected.contains((e as Map)['session_id'])),
          );
          events.removeWhere(
            (e) => rejected.contains((e as Map)['session_id']),
          );
          if (unconfirmed.length > maxPending) {
            unconfirmed.removeRange(0, unconfirmed.length - maxPending);
          }
        });
        for (final lesson in changed) {
          developer.log(
            'Server confirmed activity or lesson completion for $lesson.',
            name: 'CBOA.LearningProgress',
          );
          changes.add(lesson);
        }
        // Every acknowledgement is on disk before requesting the next batch.
      }
    } catch (error, stackTrace) {
      developer.log(
        'Progress sync failed; queued samples retained.',
        name: 'CBOA.LearningProgress',
        error: error,
        stackTrace: stackTrace,
      );
      // Lost responses retry the same identities. Confirmed server progress is
      // never inferred from an optimistic client result or an erased queue.
    } finally {
      _syncing.remove(owner);
    }
  }

  Future<String?> pendingMessage(String lesson) async {
    final owner = user;
    if (owner == null) return null;
    return store.read(owner, (data) async {
      final error = (data['errors'] as Map)[lesson] as String?;
      if (error != null) return error;
      if ((data['material_opens'] as Map? ?? {}).values.whereType<Map>().any(
        (item) => item['lesson_id'] == lesson,
      )) {
        return 'Handout opened. Completion syncs when online.';
      }
      final ids = (data['tickets'] as Map).values
          .whereType<Map>()
          .where((t) => t['lesson_id'] == lesson)
          .map((t) => t['id'])
          .toSet();
      return (data['events'] as List).any(
            (e) => ids.contains((e as Map)['session_id']),
          )
          ? 'Progress saved on this device. Syncs when online.'
          : null;
    });
  }

  Future<void> confirmVideo(
    String source,
    int duration, {
    String? lessonId,
  }) async {
    await client
        .rpc(
          'confirm_learning_video',
          params: {
            'p_source': source,
            'p_duration_ms': duration,
            'p_lesson_id': lessonId,
          },
        )
        .timeout(requestTimeout);
  }
}
