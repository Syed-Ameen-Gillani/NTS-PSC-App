class CurriculumScope {
  const CurriculumScope({this.courseId, this.moduleId, this.lessonId});
  final String? courseId;
  final String? moduleId;
  final String? lessonId;
  String get targetLabel => lessonId != null
      ? 'Lesson'
      : moduleId != null
      ? 'Module'
      : 'Course';
  Map<String, dynamic> get params => {
    'p_course_id': courseId,
    'p_module_id': moduleId,
    'p_lesson_id': lessonId,
  };
  @override
  bool operator ==(Object other) =>
      other is CurriculumScope &&
      courseId == other.courseId &&
      moduleId == other.moduleId &&
      lessonId == other.lessonId;
  @override
  int get hashCode => Object.hash(courseId, moduleId, lessonId);
}

class CurriculumContext {
  const CurriculumContext({
    required this.scope,
    required this.title,
    required this.courseTitle,
    required this.canManage,
  });
  final CurriculumScope scope;
  final String title;
  final String courseTitle;
  final bool canManage;
  factory CurriculumContext.fromRow(Map<String, dynamic> row) =>
      CurriculumContext(
        scope: CurriculumScope(
          courseId: row['course_id'],
          moduleId: row['module_id'],
          lessonId: row['lesson_id'],
        ),
        title: row['title'] as String,
        courseTitle: row['course_title'] as String,
        canManage: row['can_manage'] == true,
      );
}

class CurriculumMaterial {
  const CurriculumMaterial({
    required this.id,
    required this.title,
    required this.path,
    required this.sizeBytes,
  });
  final String id;
  final String title;
  final String path;
  final int sizeBytes;
  factory CurriculumMaterial.fromRow(Map<String, dynamic> row) =>
      CurriculumMaterial(
        id: row['id'] as String,
        title: row['title'] as String,
        path: row['object_path'] as String,
        sizeBytes: (row['size_bytes'] as num).toInt(),
      );
}

class CurriculumAssessment {
  const CurriculumAssessment({
    required this.id,
    required this.assessmentId,
    required this.title,
    required this.kind,
    required this.status,
  });
  final String id;
  final String assessmentId;
  final String title;
  final String kind;
  final String status;
  factory CurriculumAssessment.fromRow(Map<String, dynamic> row) {
    final quiz = row['quizzes'];
    final assignment = row['assignments'];
    final source = (quiz ?? assignment) as Map<String, dynamic>?;
    return CurriculumAssessment(
      id: row['id'] as String,
      assessmentId: (row['quiz_id'] ?? row['assignment_id']) as String,
      title: source?['title'] as String? ?? 'Assessment unavailable',
      kind: row['quiz_id'] != null ? 'quiz' : 'assignment',
      status: source?['status'] as String? ?? 'draft',
    );
  }
  factory CurriculumAssessment.candidate(Map<String, dynamic> row) =>
      CurriculumAssessment(
        id: row['id'],
        assessmentId: row['id'],
        title: row['title'],
        kind: row['kind'],
        status: row['status'],
      );
}

typedef PendingMaterial = ({String path, String name, int sizeBytes});
const maxCurriculumMaterialBytes = 25 * 1024 * 1024;
const curriculumMimeTypes = {
  'pdf': 'application/pdf',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'txt': 'text/plain',
};
String materialExtension(String name) => name.split('.').last.toLowerCase();
void validateCurriculumMaterial(String name, int size) {
  if (!curriculumMimeTypes.containsKey(materialExtension(name))) {
    throw ArgumentError('Choose a PDF, DOCX, PPTX, or text file.');
  }
  if (size < 1 || size > maxCurriculumMaterialBytes) {
    throw ArgumentError('Choose a document no larger than 25 MB.');
  }
  if (name.trim().isEmpty || name.length > 200) {
    throw ArgumentError('Use a filename of up to 200 characters.');
  }
}
