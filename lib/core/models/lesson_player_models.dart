import 'package:flutter/foundation.dart';

/// Immutable model representing an in-video quiz/knowledge check (Coursera-style).
@immutable
class InVideoQuizModel {
  final String id;
  final String lessonId;
  final int timestampSeconds;
  final String timestampDisplay;
  final String topic;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String hint;
  final bool isMandatory;
  final bool isCompleted;

  const InVideoQuizModel({
    required this.id,
    required this.lessonId,
    required this.timestampSeconds,
    required this.timestampDisplay,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.hint,
    this.isMandatory = true,
    this.isCompleted = false,
  });

  InVideoQuizModel copyWith({
    String? id,
    String? lessonId,
    int? timestampSeconds,
    String? timestampDisplay,
    String? topic,
    String? question,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    String? hint,
    bool? isMandatory,
    bool? isCompleted,
  }) {
    return InVideoQuizModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      timestampDisplay: timestampDisplay ?? this.timestampDisplay,
      topic: topic ?? this.topic,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      isMandatory: isMandatory ?? this.isMandatory,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Result of evaluating an in-video quiz submission.
@immutable
class QuizSubmissionResult {
  final bool isCorrect;
  final String explanation;
  final String hint;
  final int selectedIndex;

  const QuizSubmissionResult({
    required this.isCorrect,
    required this.explanation,
    required this.hint,
    required this.selectedIndex,
  });
}

/// Student's personal lesson notebook entry.
@immutable
class LessonPersonalNote {
  final String lessonId;
  final String content;
  final DateTime updatedAt;
  final bool isSaved;

  const LessonPersonalNote({
    required this.lessonId,
    required this.content,
    required this.updatedAt,
    this.isSaved = true,
  });

  LessonPersonalNote copyWith({
    String? lessonId,
    String? content,
    DateTime? updatedAt,
    bool? isSaved,
  }) {
    return LessonPersonalNote(
      lessonId: lessonId ?? this.lessonId,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// Threaded discussion message for a specific lesson.
@immutable
class LessonDiscussionItem {
  final String id;
  final String studentName;
  final String studentInitial;
  final String timeAgo;
  final String question;
  final bool isResolved;
  final String? instructorReply;
  final String? instructorName;

  const LessonDiscussionItem({
    required this.id,
    required this.studentName,
    required this.studentInitial,
    required this.timeAgo,
    required this.question,
    this.isResolved = false,
    this.instructorReply,
    this.instructorName,
  });

  LessonDiscussionItem copyWith({
    String? id,
    String? studentName,
    String? studentInitial,
    String? timeAgo,
    String? question,
    bool? isResolved,
    String? instructorReply,
    String? instructorName,
  }) {
    return LessonDiscussionItem(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentInitial: studentInitial ?? this.studentInitial,
      timeAgo: timeAgo ?? this.timeAgo,
      question: question ?? this.question,
      isResolved: isResolved ?? this.isResolved,
      instructorReply: instructorReply ?? this.instructorReply,
      instructorName: instructorName ?? this.instructorName,
    );
  }
}
