import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveMeeting {
  const LiveMeeting({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.url,
    required this.startsAt,
    required this.minutes,
    required this.cancelled,
  });
  final String id, title, courseTitle, url;
  final DateTime startsAt;
  final int minutes;
  final bool cancelled;
  bool get ended =>
      DateTime.now().isAfter(startsAt.add(Duration(minutes: minutes)));
}

final liveSessionRepositoryProvider = Provider(
  (ref) => LiveSessionRepository(Supabase.instance.client),
);
final liveMeetingsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(liveSessionRepositoryProvider).list(),
);

class LiveSessionRepository {
  LiveSessionRepository(this.client);
  final SupabaseClient client;

  static bool validMeetingUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.contains('.') &&
        uri.userInfo.isEmpty &&
        !RegExp(r'\s').hasMatch(value);
  }

  Future<List<LiveMeeting>> list() async {
    final rows = await client
        .from('live_sessions')
        .select('*,courses(title)')
        .order('starts_at');
    return rows
        .map(
          (row) => LiveMeeting(
            id: row['id'] as String,
            title: row['title'] as String,
            courseTitle:
                (row['courses'] as Map?)?['title'] as String? ?? 'Course',
            url: row['meeting_url'] as String,
            startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
            minutes: row['duration_minutes'] as int,
            cancelled: row['cancelled'] as bool,
          ),
        )
        .toList();
  }

  Future<void> schedule({
    required String courseId,
    required String title,
    required String url,
    required DateTime startsAt,
    required int minutes,
  }) async {
    if (!validMeetingUrl(url) ||
        title.trim().isEmpty ||
        title.trim().length > 200 ||
        !startsAt.isAfter(DateTime.now()) ||
        minutes < 5 ||
        minutes > 480) {
      throw ArgumentError(
        'Enter a title, HTTPS meeting link, future time and 5-480 minute duration.',
      );
    }
    await client.from('live_sessions').insert({
      'course_id': courseId,
      'title': title.trim(),
      'meeting_url': url.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'duration_minutes': minutes,
    });
  }

  Future<void> cancel(String id) async {
    await client
        .from('live_sessions')
        .update({'cancelled': true})
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> join(LiveMeeting meeting) async {
    // Re-read authorization and cancellation immediately before opening the link.
    final row = await client
        .from('live_sessions')
        .select('meeting_url,cancelled,starts_at,duration_minutes')
        .eq('id', meeting.id)
        .single();
    final end = DateTime.parse(
      row['starts_at'] as String,
    ).add(Duration(minutes: row['duration_minutes'] as int));
    final url = row['meeting_url'] as String;
    if (row['cancelled'] == true ||
        DateTime.now().isAfter(end) ||
        !validMeetingUrl(url)) {
      throw StateError('This meeting is no longer available.');
    }
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('Could not open the meeting link.');
    }
  }
}
