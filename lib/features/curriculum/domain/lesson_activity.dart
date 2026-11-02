/// Published outline metadata. It never contains answers, file URLs or notes.
class LessonActivity {
  const LessonActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.order,
    required this.isRequired,
    this.materialId,
    this.assessmentLinkId,
  });

  final String id;
  final String kind;
  final String title;
  final int order;
  final bool isRequired;
  final String? materialId;
  final String? assessmentLinkId;

  factory LessonActivity.fromRow(Map<String, dynamic> row) => LessonActivity(
    id: row['id'] as String,
    kind: row['kind'] as String,
    title: row['title'] as String? ?? '',
    order: (row['display_order'] as num).toInt(),
    isRequired: row['required'] == true,
    materialId: row['material_id'] as String?,
    assessmentLinkId: row['assessment_link_id'] as String?,
  );
}
