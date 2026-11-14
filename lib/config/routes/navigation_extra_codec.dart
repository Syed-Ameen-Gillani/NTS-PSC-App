import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_wallet_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_question_screen.dart';

/// Live decoder controllers cannot survive a process. Their underlying lesson
/// route is restored instead, with its existing saved playback position.
class TransientNavigationExtra {
  const TransientNavigationExtra();
}

/// Preserves typed navigation arguments in Android's account-scoped restoration
/// bundle. Compression keeps course outlines from inflating the saved back stack.
/// These snapshots never replace the existing backend access checks.
class NavigationExtraCodec extends Codec<Object?, Object?> {
  const NavigationExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => const _NavigationExtraEncoder();
  @override
  Converter<Object?, Object?> get decoder => const _NavigationExtraDecoder();
}

class _NavigationExtraEncoder extends Converter<Object?, Object?> {
  const _NavigationExtraEncoder();

  @override
  Object? convert(Object? input) {
    final payload = jsonEncode(_encode(input));
    return kIsWeb
        ? 'json:$payload'
        : 'gzip:${base64Encode(gzip.encode(utf8.encode(payload)))}';
  }
}

class _NavigationExtraDecoder extends Converter<Object?, Object?> {
  const _NavigationExtraDecoder();

  @override
  Object? convert(Object? input) {
    try {
      if (input is! String) return null;
      final String payload;
      if (input.startsWith('json:')) {
        payload = input.substring(5);
      } else if (!kIsWeb && input.startsWith('gzip:')) {
        payload = utf8.decode(gzip.decode(base64Decode(input.substring(5))));
      } else {
        return null;
      }
      return _decode(jsonDecode(payload));
    } catch (_) {
      LifecycleDiagnostics.event('restoration', 'discard-invalid-extra');
      return null;
    }
  }
}

Object? _object(String type, Map<String, Object?> fields) => {
  'type': type,
  'data': _encode(fields),
};

Object? _encode(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) return value.map(_encode).toList();
  if (value is Map) {
    return {
      'type': 'map',
      'data': [
        for (final entry in value.entries)
          [_encode(entry.key), _encode(entry.value)],
      ],
    };
  }
  if (value is DateTime) {
    return {'type': 'DateTime', 'data': value.toIso8601String()};
  }
  if (value is CourseViewMode) {
    return {'type': 'CourseViewMode', 'data': value.name};
  }
  if (value is LessonPlayerMode) {
    return {'type': 'LessonPlayerMode', 'data': value.name};
  }
  if (value is WalletType) return {'type': 'WalletType', 'data': value.name};
  if (value is AssessmentCreationRequest) {
    return _object('AssessmentCreationRequest', {
      'targetScope': value.targetScope,
    });
  }
  if (value is CourseModel) {
    return _object('CourseModel', {
      'id': value.id,
      'title': value.title,
      'author': value.author,
      'rating': value.rating,
      'price': value.price,
      'priceAmount': value.priceAmount,
      'currency': value.currency,
      'hasEntitlement': value.hasEntitlement,
      'imagePath': value.imagePath,
      'coverUrl': value.coverUrl,
      'isFeatured': value.isFeatured,
      'progress': value.progress,
      'description': value.description,
      'instructorId': value.instructorId,
      'category': value.category,
      'enrolledCount': value.enrolledCount,
      'isPublished': value.isPublished,
      'learningComplete': value.learningComplete,
      'remainingAssessments': value.remainingAssessments,
      'modules': value.modules,
    });
  }
  if (value is CourseModuleModel) {
    return _object('CourseModuleModel', {
      'id': value.id,
      'title': value.title,
      'lessons': value.lessons,
    });
  }
  if (value is LessonModel) {
    return _object('LessonModel', {
      'id': value.id,
      'title': value.title,
      'durationMinutes': value.durationMinutes,
      'videoUrl': value.videoUrl,
      'videoPath': value.videoPath,
      'notes': value.notes,
      'isCompleted': value.isCompleted,
      'isLocked': value.isLocked,
      'accessState': value.accessState,
      'activities': value.activities,
    });
  }
  if (value is LessonActivity) {
    return _object('LessonActivity', {
      'id': value.id,
      'kind': value.kind,
      'title': value.title,
      'order': value.order,
      'isRequired': value.isRequired,
      'materialId': value.materialId,
      'assessmentLinkId': value.assessmentLinkId,
    });
  }
  if (value is CategoryModel) {
    return _object('CategoryModel', {
      'id': value.id,
      'name': value.name,
      'courseCount': value.courseCount,
      'iconType': value.iconType,
    });
  }
  if (value is TeacherModel) {
    return _object('TeacherModel', {
      'id': value.id,
      'name': value.name,
      'subject': value.subject,
      'imagePath': value.imagePath,
      'qualification': value.qualification,
      'bio': value.bio,
      'rating': value.rating,
      'studentCount': value.studentCount,
    });
  }
  if (value is QuizModel) {
    return _object('QuizModel', {
      'id': value.id,
      'title': value.title,
      'category': value.category,
      'isAiGenerated': value.isAiGenerated,
      'totalQuestions': value.totalQuestions,
      'score': value.score,
      'durationMinutes': value.durationMinutes,
      'passingScore': value.passingScore,
      'difficulty': value.difficulty,
      'questions': value.questions,
      'isPublished': value.isPublished,
      'courseId': value.courseId,
      'attemptId': value.attemptId,
    });
  }
  if (value is QuizQuestionModel) {
    return _object('QuizQuestionModel', {
      'id': value.id,
      'questionText': value.questionText,
      'options': value.options,
      'correctOptionIndex': value.correctOptionIndex,
      'explanation': value.explanation,
    });
  }
  if (value is QuizSubmissionResultModel) {
    return _object('QuizSubmissionResultModel', {
      'attemptId': value.attemptId,
      'passingScore': value.passingScore,
      'quizId': value.quizId,
      'quizTitle': value.quizTitle,
      'score': value.score,
      'totalQuestions': value.totalQuestions,
      'userAnswers': value.userAnswers,
      'questions': value.questions,
    });
  }
  if (value is AssignmentModel) {
    return _object('AssignmentModel', {
      'id': value.id,
      'courseId': value.courseId,
      'courseTitle': value.courseTitle,
      'title': value.title,
      'instructions': value.instructions,
      'externalUrl': value.externalUrl,
      'dueAt': value.dueAt,
      'isPublished': value.isPublished,
      'attachments': value.attachments,
    });
  }
  if (value is AssignmentAttachmentModel) {
    return _object('AssignmentAttachmentModel', {
      'name': value.name,
      'sizeBytes': value.sizeBytes,
      'path': value.path,
    });
  }
  if (value is CurriculumScope) {
    return _object('CurriculumScope', {
      'courseId': value.courseId,
      'moduleId': value.moduleId,
      'lessonId': value.lessonId,
    });
  }
  if (value is QuizQuestionEditorArgs) {
    return _object('QuizQuestionEditorArgs', {
      'number': value.number,
      'question': value.question,
    });
  }
  return {'type': 'transient', 'data': null};
}

Object? _decode(Object? value) {
  if (value is List) return value.map(_decode).toList();
  if (value is! Map) return value;
  final type = value['type'];
  final raw = value['data'];
  if (type == 'map') {
    final entries = (raw as List)
        .map((entry) => MapEntry(_decode(entry[0]), _decode(entry[1])))
        .toList();
    if (entries.every((entry) => entry.key is String)) {
      return <String, dynamic>{
        for (final entry in entries) entry.key as String: entry.value,
      };
    }
    return {for (final entry in entries) entry.key: entry.value};
  }
  if (type == 'DateTime') return DateTime.parse(raw as String);
  if (type == 'CourseViewMode') {
    return CourseViewMode.values.byName(raw as String);
  }
  if (type == 'LessonPlayerMode') {
    return LessonPlayerMode.values.byName(raw as String);
  }
  if (type == 'WalletType') return WalletType.values.byName(raw as String);
  if (type == 'transient') return const TransientNavigationExtra();
  final data = _decode(raw) as Map<String, dynamic>;
  switch (type) {
    case 'AssessmentCreationRequest':
      return AssessmentCreationRequest(data['targetScope'] as CurriculumScope);
    case 'CourseModel':
      return CourseModel(
        id: data['id'] as String,
        title: data['title'] as String,
        author: data['author'] as String,
        rating: (data['rating'] as num).toDouble(),
        price: data['price'] as String,
        priceAmount: data['priceAmount'] as int?,
        currency: data['currency'] as String,
        hasEntitlement: data['hasEntitlement'] as bool,
        imagePath: data['imagePath'] as String,
        coverUrl: data['coverUrl'] as String?,
        isFeatured: data['isFeatured'] as bool,
        progress: (data['progress'] as num?)?.toDouble(),
        description: data['description'] as String,
        instructorId: data['instructorId'] as String,
        category: data['category'] as String,
        enrolledCount: data['enrolledCount'] as int,
        isPublished: data['isPublished'] as bool,
        learningComplete: data['learningComplete'] as bool?,
        remainingAssessments: data['remainingAssessments'] as int,
        modules: (data['modules'] as List).cast<CourseModuleModel>(),
      );
    case 'CourseModuleModel':
      return CourseModuleModel(
        id: data['id'] as String,
        title: data['title'] as String,
        lessons: (data['lessons'] as List).cast<LessonModel>(),
      );
    case 'LessonModel':
      return LessonModel(
        id: data['id'] as String,
        title: data['title'] as String,
        durationMinutes: data['durationMinutes'] as int,
        videoUrl: data['videoUrl'] as String,
        videoPath: data['videoPath'] as String,
        notes: data['notes'] as String,
        isCompleted: data['isCompleted'] as bool,
        isLocked: data['isLocked'] as bool,
        accessState: data['accessState'] as String?,
        activities: (data['activities'] as List).cast<LessonActivity>(),
      );
    case 'LessonActivity':
      return LessonActivity(
        id: data['id'] as String,
        kind: data['kind'] as String,
        title: data['title'] as String,
        order: data['order'] as int,
        isRequired: data['isRequired'] as bool,
        materialId: data['materialId'] as String?,
        assessmentLinkId: data['assessmentLinkId'] as String?,
      );
    case 'CategoryModel':
      return CategoryModel(
        id: data['id'] as String,
        name: data['name'] as String,
        courseCount: data['courseCount'] as int,
        iconType: data['iconType'] as String,
      );
    case 'TeacherModel':
      return TeacherModel(
        id: data['id'] as String,
        name: data['name'] as String,
        subject: data['subject'] as String,
        imagePath: data['imagePath'] as String,
        qualification: data['qualification'] as String,
        bio: data['bio'] as String,
        rating: (data['rating'] as num).toDouble(),
        studentCount: data['studentCount'] as int,
      );
    case 'QuizModel':
      return QuizModel(
        id: data['id'] as String,
        title: data['title'] as String,
        category: data['category'] as String,
        isAiGenerated: data['isAiGenerated'] as bool,
        totalQuestions: data['totalQuestions'] as int,
        score: data['score'] as String?,
        durationMinutes: data['durationMinutes'] as int,
        passingScore: data['passingScore'] as int,
        difficulty: data['difficulty'] as String,
        questions: (data['questions'] as List).cast<QuizQuestionModel>(),
        isPublished: data['isPublished'] as bool,
        courseId: data['courseId'] as String?,
        attemptId: data['attemptId'] as String?,
      );
    case 'QuizQuestionModel':
      return QuizQuestionModel(
        id: data['id'] as String,
        questionText: data['questionText'] as String,
        options: (data['options'] as List).cast<String>(),
        correctOptionIndex: data['correctOptionIndex'] as int,
        explanation: data['explanation'] as String,
      );
    case 'QuizSubmissionResultModel':
      return QuizSubmissionResultModel(
        attemptId: data['attemptId'] as String?,
        passingScore: data['passingScore'] as int,
        quizId: data['quizId'] as String,
        quizTitle: data['quizTitle'] as String,
        score: data['score'] as int,
        totalQuestions: data['totalQuestions'] as int,
        userAnswers: (data['userAnswers'] as Map).cast<int, int>(),
        questions: (data['questions'] as List).cast<QuizQuestionModel>(),
      );
    case 'AssignmentModel':
      return AssignmentModel(
        id: data['id'] as String,
        courseId: data['courseId'] as String,
        courseTitle: data['courseTitle'] as String,
        title: data['title'] as String,
        instructions: data['instructions'] as String,
        externalUrl: data['externalUrl'] as String?,
        dueAt: data['dueAt'] as DateTime,
        isPublished: data['isPublished'] as bool,
        attachments: (data['attachments'] as List)
            .cast<AssignmentAttachmentModel>(),
      );
    case 'AssignmentAttachmentModel':
      return AssignmentAttachmentModel(
        name: data['name'] as String,
        sizeBytes: data['sizeBytes'] as int,
        path: data['path'] as String?,
      );
    case 'CurriculumScope':
      return CurriculumScope(
        courseId: data['courseId'] as String?,
        moduleId: data['moduleId'] as String?,
        lessonId: data['lessonId'] as String?,
      );
    case 'QuizQuestionEditorArgs':
      return QuizQuestionEditorArgs(
        number: data['number'] as int,
        question: data['question'] as QuizQuestionModel?,
      );
    default:
      return null;
  }
}
