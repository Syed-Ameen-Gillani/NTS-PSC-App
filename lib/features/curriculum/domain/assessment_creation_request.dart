import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';

/// Preserves the exact Lesson Studio location while an assessment is authored.
class AssessmentCreationRequest {
  const AssessmentCreationRequest(this.targetScope);

  final CurriculumScope targetScope;
}
