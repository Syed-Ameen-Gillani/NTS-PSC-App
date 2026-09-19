import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/repositories/lesson_player_repository.dart';

/// Senior Clean Architecture Dependency Injection:
///
/// This provider serves as the single source of truth for the data layer.
/// To plug in a real database (e.g., Supabase, Firebase, or GraphQL backend):
/// 1. Implement `ILessonPlayerRepository` with your real database client.
/// 2. Change the return value below to `YourRemoteLessonPlayerRepository(client)`.
/// Zero modifications are needed in UI screens, widgets, or controllers!
final lessonPlayerRepositoryProvider = Provider<ILessonPlayerRepository>((ref) {
  return MockLessonPlayerRepository();
});
