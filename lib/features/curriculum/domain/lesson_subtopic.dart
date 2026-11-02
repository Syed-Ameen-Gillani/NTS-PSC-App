import 'package:flutter/material.dart';
import 'curriculum_models.dart';
import 'lesson_activity.dart';

enum LessonSubTopicKind {
  quiz,
  assignment,
  handout,
  reading,
}

class LessonSubTopic {
  final String id;
  final String title;
  final LessonSubTopicKind kind;
  final bool isRequired;
  final String? assessmentId;
  final String? materialId;
  final String? materialPath;

  const LessonSubTopic({
    required this.id,
    required this.title,
    required this.kind,
    this.isRequired = false,
    this.assessmentId,
    this.materialId,
    this.materialPath,
  });

  String get kindLabel => switch (kind) {
    LessonSubTopicKind.quiz => 'Quiz',
    LessonSubTopicKind.assignment => 'Assignment',
    LessonSubTopicKind.handout => 'Handout',
    LessonSubTopicKind.reading => 'Reading',
  };

  IconData get icon => switch (kind) {
    LessonSubTopicKind.quiz => Icons.quiz_outlined,
    LessonSubTopicKind.assignment => Icons.assignment_outlined,
    LessonSubTopicKind.handout => Icons.description_outlined,
    LessonSubTopicKind.reading => Icons.article_outlined,
  };

  static LessonSubTopic? fromActivity(LessonActivity activity) {
    final kind = switch (activity.kind) {
      'quiz' => LessonSubTopicKind.quiz,
      'assignment' => LessonSubTopicKind.assignment,
      'material' => LessonSubTopicKind.handout,
      'reading' => LessonSubTopicKind.reading,
      _ => null,
    };
    if (kind == null) return null;
    return LessonSubTopic(
      id: activity.id,
      title: activity.title.isNotEmpty ? activity.title : kind.name,
      kind: kind,
      isRequired: activity.isRequired,
    );
  }

  static LessonSubTopic fromAssessment(CurriculumAssessment assessment) {
    final kind = assessment.kind == 'assignment'
        ? LessonSubTopicKind.assignment
        : LessonSubTopicKind.quiz;
    return LessonSubTopic(
      id: assessment.id,
      assessmentId: assessment.assessmentId,
      title: assessment.title,
      kind: kind,
    );
  }

  static LessonSubTopic fromMaterial(CurriculumMaterial material) {
    return LessonSubTopic(
      id: material.id,
      materialId: material.id,
      materialPath: material.path,
      title: material.title,
      kind: LessonSubTopicKind.handout,
    );
  }
}
