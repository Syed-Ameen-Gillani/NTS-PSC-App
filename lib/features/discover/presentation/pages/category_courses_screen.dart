import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/catalog_pages_controller.dart';
import 'package:nts_psc_app/presentation/widgets/browse_category_grid.dart';

class CategoryCoursesScreen extends ConsumerWidget {
  final CategoryModel? category;

  const CategoryCoursesScreen({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category == null) {
      return const _AllCategoriesScreen();
    }
    final paged = AppConfig.isSupabaseEnabled;
    final listKey = (section: 'available', category: category!.name);
    final page = paged ? ref.watch(catalogPageIndexProvider(listKey)) : 0;
    final pages = paged
        ? ref.watch(catalogPagesProvider((list: listKey, page: page)))
        : null;
    final previousPages = paged && page > 0
        ? ref.watch(catalogPagesProvider((list: listKey, page: page - 1)))
        : null;
    final loadingMore =
        paged && pages!.isLoading && previousPages?.hasValue == true;
    final loadMoreError =
        paged && pages!.hasError && previousPages?.hasValue == true;
    final visiblePages = loadingMore || loadMoreError ? previousPages! : pages;
    final courses = paged
        ? visiblePages!.whenData(
            (parts) => parts.expand((items) => items).toList(),
          )
        : ref.watch(categoryCoursesProvider(category!.name));
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          category?.name ?? 'All Categories',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: courses.when(
          data: (items) => items.isEmpty
              ? Center(
                  child: Text(
                    'No courses available',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
                  itemCount:
                      items.length +
                      1 +
                      (paged &&
                              (loadingMore ||
                                  loadMoreError ||
                                  pages!.value?.last.length == catalogPageSize)
                          ? 1
                          : 0),
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          paged
                              ? '${items.length} courses shown'
                              : '${items.length} ${items.length == 1 ? 'course' : 'courses'}',
                          style: AppTextStyles.interMedium16.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      );
                    }
                    if (index == items.length + 1) {
                      return Center(
                        child: loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: loadMoreError
                                    ? () => ref.invalidate(
                                        catalogPageProvider((
                                          list: listKey,
                                          page: page,
                                        )),
                                      )
                                    : ref
                                          .read(
                                            catalogPageIndexProvider(
                                              listKey,
                                            ).notifier,
                                          )
                                          .next,
                                child: Text(
                                  loadMoreError ? 'Retry' : 'Show more',
                                ),
                              ),
                      );
                    }
                    return _CategoryCourseTile(course: items[index - 1]);
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () {
                if (paged) {
                  for (var index = 0; index <= page; index++) {
                    ref.invalidate(
                      catalogPageProvider((list: listKey, page: index)),
                    );
                  }
                } else {
                  ref.invalidate(categoryCoursesProvider(category!.name));
                }
              },
              child: const Text('Could not load courses. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllCategoriesScreen extends ConsumerWidget {
  const _AllCategoriesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'All Categories',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: categories.when(
          data: (items) => items.isEmpty
              ? Center(
                  child: Text(
                    'No categories available',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.only(top: 24.h, bottom: 32.h),
                  child: BrowseCategoryGrid(
                    title: '${items.length} categories',
                    actionText: '',
                    showAction: false,
                    categories: items,
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(allCategoriesProvider),
              child: const Text('Could not load categories. Retry'),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCourseTile extends StatelessWidget {
  final CourseModel course;

  const _CategoryCourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(AppRoute.courseDetail.name, extra: course),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: DashboardCourseCover(
                imagePath: course.imagePath,
                coverUrl: course.coverUrl,
                width: 96.w,
                height: 96.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    course.author,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (course.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                              size: 16.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        course.price,
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
