import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';

class LessonModel {
  final String id;
  final String title;
  final int durationMinutes;
  final String videoUrl;
  final String videoPath;
  final String notes;
  final bool isCompleted;
  final bool isLocked;
  final String? accessState;
  final List<LessonActivity> activities;

  LessonModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.videoUrl = '',
    this.videoPath = '',
    this.notes = '',
    this.isCompleted = false,
    this.isLocked = false,
    this.accessState,
    this.activities = const [],
  });

  LessonModel copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    String? videoUrl,
    String? videoPath,
    String? notes,
    bool? isCompleted,
    bool? isLocked,
    String? accessState,
    List<LessonActivity>? activities,
  }) => LessonModel(
    id: id ?? this.id,
    title: title ?? this.title,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    videoUrl: videoUrl ?? this.videoUrl,
    videoPath: videoPath ?? this.videoPath,
    notes: notes ?? this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
    isLocked: isLocked ?? this.isLocked,
    accessState: accessState ?? this.accessState,
    activities: activities ?? this.activities,
  );
}
