import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lesson_activity.dart';

final lessonActivityRepositoryProvider = Provider(
  (ref) => LessonActivityRepository(Supabase.instance.client),
);

class LessonActivityRepository {
  LessonActivityRepository(this.client);
  final SupabaseClient client;
  Future<List<ConfiguredActivity>> list(String lesson) async =>
      (await client.rpc(
                'get_teacher_lesson_activities',
                params: {'p_lesson_id': lesson},
              )
              as List)
          .cast<Map>()
          .map(
            (row) => ConfiguredActivity(
              LessonActivity.fromRow(Map<String, dynamic>.from(row)),
              row['warning'] as String?,
              materialId: row['material_id'] as String?,
              canPrepare: row['can_prepare'] == true,
              readingReady: row['reading_ready'] == true,
            ),
          )
          .toList();
  Future<void> save(String lesson, List<ConfiguredActivity> activities) async {
    await client.rpc(
      'configure_lesson_activities',
      params: {
        'p_lesson_id': lesson,
        'p_items': [
          for (final item in activities)
            {'id': item.activity.id, 'required': item.activity.isRequired},
        ],
      },
    );
  }

  Future<void> prepare(String materialId) async {
    await client.functions.invoke(
      'prepare-lesson-reading',
      body: {'materialId': materialId},
    );
  }
}

class ConfiguredActivity {
  const ConfiguredActivity(
    this.activity,
    this.warning, {
    this.materialId,
    this.canPrepare = false,
    this.readingReady = false,
  });
  final LessonActivity activity;
  final String? warning;
  final String? materialId;
  final bool canPrepare;
  final bool readingReady;
  ConfiguredActivity required(bool value) => ConfiguredActivity(
    LessonActivity(
      id: activity.id,
      kind: activity.kind,
      title: activity.title,
      order: activity.order,
      isRequired: value,
      materialId: activity.materialId,
      assessmentLinkId: activity.assessmentLinkId,
    ),
    warning,
    materialId: materialId,
    canPrepare: canPrepare,
    readingReady: readingReady,
  );
}
