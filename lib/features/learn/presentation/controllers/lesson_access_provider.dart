import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

/// Rehydrates protected routes by ID after session restoration/account changes.
final lessonAccessCourseProvider = FutureProvider.autoDispose
    .family<CourseModel?, String>((ref, id) async {
      ref.watch(
        authControllerProvider.select((value) => value.value?.user?.id),
      );
      final auth = await ref.watch(authControllerProvider.future);
      if (auth.user == null) return null;
      return ref.watch(courseRepositoryProvider).getCourseById(id);
    });
