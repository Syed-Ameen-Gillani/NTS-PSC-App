import 'package:flutter/material.dart';
import 'package:nts_psc_app/core/models/lesson_model.dart';

/// Single source of truth for standard lesson classification across student and teacher roles:
/// - Video Lesson: contains video, regardless of assessments or handouts.
/// - Assessment: no video, but contains an assessment (quiz/assignment).
/// - Reading Lesson: neither video nor assessment.
class LessonClassification {
  static const videoLesson = 'Video lesson';
  static const assessment = 'Assessment';
  static const readingLesson = 'Reading lesson';

  static bool hasVideo(LessonModel lesson) =>
      lesson.videoUrl.isNotEmpty ||
      lesson.videoPath.isNotEmpty ||
      lesson.activities.any((a) => a.kind == 'video');

  static bool hasAssessment(
    LessonModel lesson, {
    bool hasExternalAssessment = false,
  }) {
    if (hasExternalAssessment) return true;
    return lesson.activities.any(
      (a) => a.kind == 'quiz' || a.kind == 'assignment',
    );
  }

  static String classify(
    LessonModel lesson, {
    bool hasExternalAssessment = false,
  }) {
    if (hasVideo(lesson)) return videoLesson;
    if (hasAssessment(lesson, hasExternalAssessment: hasExternalAssessment)) {
      return assessment;
    }
    return readingLesson;
  }

  static IconData icon(
    LessonModel lesson, {
    bool hasExternalAssessment = false,
  }) {
    if (hasVideo(lesson)) return Icons.play_circle_outline;
    if (hasAssessment(lesson, hasExternalAssessment: hasExternalAssessment)) {
      return Icons.quiz_outlined;
    }
    return Icons.article_outlined;
  }
}
