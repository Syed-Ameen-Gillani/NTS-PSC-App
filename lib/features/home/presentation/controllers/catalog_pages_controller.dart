import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

const catalogPageSize = 20;
typedef CatalogListKey = ({String section, String? category});
typedef CatalogPageRequest = ({CatalogListKey list, int page});

class CatalogPageIndex extends Notifier<int> {
  CatalogPageIndex(this.list);
  final CatalogListKey list;

  @override
  int build() => 0;

  void next() => state++;
}

final catalogPageIndexProvider = NotifierProvider.autoDispose
    .family<CatalogPageIndex, int, CatalogListKey>(CatalogPageIndex.new);

final catalogPageProvider = FutureProvider.autoDispose
    .family<List<CourseModel>, CatalogPageRequest>((ref, request) async {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      final courses =
          await (ref.read(courseRepositoryProvider) as SupabaseCourseRepository)
              .getNewCoursesPage(
                offset: request.page * catalogPageSize,
                limit: catalogPageSize,
                category: request.list.category,
                featuredOnly: request.list.section == 'featured',
              );
      if (!ref.mounted) return courses;
      final cache = ref.keepAlive();
      Timer? expiry;
      ref.onCancel(() {
        expiry?.cancel();
        expiry = Timer(const Duration(minutes: 3), cache.close);
      });
      ref.onResume(() => expiry?.cancel());
      ref.onDispose(() => expiry?.cancel());
      return courses;
    });

final catalogPagesProvider = FutureProvider.autoDispose
    .family<List<List<CourseModel>>, CatalogPageRequest>((ref, request) {
      return Future.wait([
        for (var page = 0; page <= request.page; page++)
          ref.watch(
            catalogPageProvider((list: request.list, page: page)).future,
          ),
      ]);
    });
