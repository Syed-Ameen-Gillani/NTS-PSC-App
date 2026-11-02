import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
  (ref) => ref.read(courseRepositoryProvider).getCategories(),
);

final categoryCoursesProvider = FutureProvider.autoDispose
    .family<List<CourseModel>, String?>((ref, category) {
      ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      return ref.read(courseRepositoryProvider).getCoursesByCategory(category);
    });
