import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';

final courseInstructorProvider = FutureProvider.autoDispose
    .family<TeacherModel?, String>((ref, id) async {
      if (id.isEmpty) return null;
      final repository = ref.watch(courseRepositoryProvider);
      final teacher = await (repository is SupabaseCourseRepository
          ? repository.getPublicTeacher(id)
          : Future<TeacherModel?>.value(null));
      if (!ref.mounted) return teacher;
      final cache = ref.keepAlive();
      Timer? expiry;
      ref.onCancel(() {
        expiry?.cancel();
        expiry = Timer(const Duration(minutes: 5), cache.close);
      });
      ref.onResume(() => expiry?.cancel());
      ref.onDispose(() => expiry?.cancel());
      return teacher;
    });
