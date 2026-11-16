import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/onboarding/domain/learning_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearningPreferencesRepository {
  LearningPreferencesRepository(this.client);
  final SupabaseClient client;

  Future<File> _cacheFile(String owner) async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/learning-interests-$owner.json');
  }

  Future<void> _cache(String owner, Map<String, dynamic> row) async {
    if (kIsWeb) return;
    try {
      await (await _cacheFile(
        owner,
      )).writeAsString(jsonEncode(row), flush: true);
    } catch (_) {
      // Server persistence succeeds independently of optional offline caching.
    }
  }

  void _requireOwner(String owner) {
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Sign in again to save your interests.');
    }
  }

  Future<LearningPreferences> load(String owner) async {
    _requireOwner(owner);
    Map<String, dynamic>? row;
    try {
      row = await client
          .from('student_learning_preferences')
          .select()
          .eq('user_id', owner)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      _requireOwner(owner);
      // Keep completed onboarding usable with existing offline learning.
      if (!kIsWeb &&
          (error is SocketException ||
              error is TimeoutException ||
              error is ClientException)) {
        try {
          final cached = LearningPreferences.fromJson(
            jsonDecode(await (await _cacheFile(owner)).readAsString())
                as Map<String, dynamic>,
          );
          _requireOwner(owner);
          if (cached.completed) return cached;
        } catch (_) {
          // Missing or invalid cached data requires a successful server read.
        }
      }
      rethrow;
    }
    _requireOwner(owner);
    if (row != null) await _cache(owner, row);
    _requireOwner(owner);
    return row == null
        ? const LearningPreferences()
        : LearningPreferences.fromJson(row);
  }

  Future<void> save(String owner, LearningPreferences preferences) async {
    preferences.validate();
    _requireOwner(owner);
    final payload = <String, dynamic>{
      'user_id': owner,
      'categories': LearningPreferences.clean(preferences.categories),
      'interests': LearningPreferences.clean(preferences.interests),
      'skills': LearningPreferences.clean(preferences.skills),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await client
        .from('student_learning_preferences')
        .upsert(payload)
        .select()
        .single()
        .timeout(const Duration(seconds: 15));
    _requireOwner(owner);
    await _cache(owner, row);
  }
}

final learningPreferencesRepositoryProvider = Provider(
  (ref) => LearningPreferencesRepository(Supabase.instance.client),
);

final learningPreferencesProvider =
    FutureProvider.family<LearningPreferences, String>((ref, owner) {
      if (!AppConfig.isSupabaseEnabled) {
        return const LearningPreferences(completed: true);
      }
      return ref.read(learningPreferencesRepositoryProvider).load(owner);
    });

final currentLearningPreferencesProvider = FutureProvider<LearningPreferences>((
  ref,
) {
  final identity = ref.watch(
    authControllerProvider.select(
      (state) => (state.value?.user?.id, state.value?.user?.role),
    ),
  );
  if (identity.$1 == null || identity.$2 != UserRole.student) {
    return const LearningPreferences(completed: true);
  }
  return ref.watch(learningPreferencesProvider(identity.$1!).future);
});
