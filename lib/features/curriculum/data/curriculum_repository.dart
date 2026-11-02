import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';

final curriculumRepositoryProvider = Provider(
  (ref) => CurriculumRepository(Supabase.instance.client),
);

class CurriculumRepository {
  CurriculumRepository(this.client);
  final SupabaseClient client;
  static const bucket = 'course-materials';

  Future<void> configureActivities(
    String lessonId,
    List<LessonActivity> items,
  ) => client.rpc(
    'configure_lesson_activities',
    params: {
      'p_lesson_id': lessonId,
      'p_items': [
        for (final item in items) {'id': item.id, 'required': item.isRequired},
      ],
    },
  );

  Future<void> stageDetails({
    required String kind,
    required String id,
    required Map<String, dynamic> changes,
  }) => client.rpc(
    'stage_curriculum_details',
    params: {'p_kind': kind, 'p_id': id, 'p_changes': changes},
  );

  Future<void> reorder({
    required String courseId,
    String? moduleId,
    required List<String> ids,
  }) => client.rpc(
    'reorder_curriculum',
    params: {'p_course_id': courseId, 'p_module_id': moduleId, 'p_ids': ids},
  );

  Future<CurriculumContext> resolve(CurriculumScope scope) async =>
      CurriculumContext.fromRow(
        Map<String, dynamic>.from(
          await client.rpc('curriculum_context', params: scope.params),
        ),
      );

  Future<List<CurriculumMaterial>> materials(CurriculumScope scope) async {
    var query = client
        .from('curriculum_materials')
        .select('id,title,object_path,size_bytes')
        .eq('status', 'ready');
    if (scope.courseId != null) {
      query = query.eq('course_id', scope.courseId!);
    }
    query = scope.moduleId == null
        ? query.isFilter('module_id', null)
        : query.eq('module_id', scope.moduleId!);
    query = scope.lessonId == null
        ? query.isFilter('lesson_id', null)
        : query.eq('lesson_id', scope.lessonId!);
    return (await query.order(
      'created_at',
    )).map(CurriculumMaterial.fromRow).toList();
  }

  Future<List<CurriculumAssessment>> assessments(CurriculumScope scope) async {
    var query = client
        .from('curriculum_assessment_links')
        .select(
          'id,quiz_id,assignment_id,quizzes(title,status),assignments(title,status)',
        );
    if (scope.courseId != null) {
      query = query.eq('course_id', scope.courseId!);
    }
    query = scope.moduleId == null
        ? query.isFilter('module_id', null)
        : query.eq('module_id', scope.moduleId!);
    query = scope.lessonId == null
        ? query.isFilter('lesson_id', null)
        : query.eq('lesson_id', scope.lessonId!);
    return (await query.order(
      'created_at',
    )).map(CurriculumAssessment.fromRow).toList();
  }

  Future<List<CurriculumAssessment>> candidates(String courseId) async =>
      (await client.rpc(
                'curriculum_assessment_candidates',
                params: {'p_course_id': courseId},
              )
              as List)
          .map(
            (row) =>
                CurriculumAssessment.candidate(Map<String, dynamic>.from(row)),
          )
          .toList();

  Future<void> link(CurriculumScope scope, CurriculumAssessment assessment) =>
      client.rpc(
        'link_curriculum_assessment',
        params: {
          ...scope.params,
          'p_kind': assessment.kind,
          'p_assessment_id': assessment.assessmentId,
        },
      );
  Future<void> unlink(String id) =>
      client.rpc('unlink_curriculum_assessment', params: {'p_link_id': id});

  Future<void> upload(CurriculumScope scope, PendingMaterial material) async {
    final size = await File(material.path).length();
    validateCurriculumMaterial(material.name, size);
    final reservation = Map<String, dynamic>.from(
      await client.rpc(
        'begin_curriculum_material',
        params: {
          ...scope.params,
          'p_title': material.name,
          'p_extension': materialExtension(material.name),
          'p_size': size,
        },
      ),
    );
    final id = reservation['id'] as String;
    final path = reservation['object_path'] as String;
    try {
      await client.storage
          .from(bucket)
          .upload(
            path,
            File(material.path),
            fileOptions: FileOptions(
              contentType: reservation['mime_type'] as String,
              upsert: false,
            ),
          );
      await client.rpc('finish_curriculum_material', params: {'p_id': id});
    } catch (_) {
      try {
        await client.storage.from(bucket).remove([path]);
        await client.from('curriculum_materials').delete().eq('id', id);
      } catch (_) {
        // A reservation is hidden from learners until successfully finalized.
      }
      rethrow;
    }
    if (scope.lessonId != null &&
        {'pdf', 'txt'}.contains(materialExtension(material.name))) {
      try {
        await client.functions
            .invoke('prepare-lesson-reading', body: {'materialId': id})
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        // Keep a valid upload. Studio exposes retry and publication checks
        // prevent an unreadable required document from reaching students.
      }
    }
  }

  Future<Uri> url(CurriculumMaterial material) async => Uri.parse(
    await client.storage.from(bucket).createSignedUrl(material.path, 60),
  );

  Future<void> delete(CurriculumMaterial material) async {
    await client.rpc(
      'stage_curriculum_removal',
      params: {'p_kind': 'material', 'p_id': material.id},
    );
  }
}
