import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import '../controllers/course_reviews_controller.dart';
import 'live_review_editor.dart';

final _reviewFilter = StateProvider.autoDispose.family<int?, String>(
  (ref, id) => null,
);

class LiveCourseReviews extends ConsumerWidget {
  const LiveCourseReviews({
    super.key,
    required this.courseId,
    this.isReadOnlyPreview = false,
  });
  final String courseId;
  final bool isReadOnlyPreview;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(_reviewFilter(courseId));
    final query = (courseId: courseId, rating: rating);
    final provider = courseReviewsProvider(query);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(provider),
              child: const Text('Could not load reviews. Retry'),
            ),
          ),
          data: (page) {
            Future<void> edit() => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  LiveReviewEditor(courseId: courseId, review: page.ownReview),
            );
            if (page.count == 0) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 300.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52.w,
                          height: 52.w,
                          decoration: const BoxDecoration(
                            color: AppColors.settingsCardBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rate_review_outlined,
                            color: AppColors.primary,
                            size: 25.w,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'No reviews yet',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 16.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          page.canReview
                              ? 'Share your learning experience with other students.'
                              : 'Reviews from enrolled students will appear here.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.grey500,
                            height: 1.4,
                          ),
                        ),
                        if (page.canReview) ...[
                          SizedBox(height: 16.h),
                          IgnorePointer(
                            ignoring: isReadOnlyPreview,
                            child: FilledButton.icon(
                              onPressed: edit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Write a review'),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${page.average.toStringAsFixed(1)} / 5',
                        style: AppTextStyles.interBold24,
                      ),
                    ),
                    Text(
                      '${page.count} ${page.count == 1 ? 'review' : 'reviews'}',
                      style: AppTextStyles.interRegular14,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (page.canReview)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IgnorePointer(
                      ignoring: isReadOnlyPreview,
                      child: TextButton.icon(
                        onPressed: edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          page.ownReview == null
                              ? 'Write a review'
                              : 'Edit your review',
                        ),
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: rating == null,
                      onSelected: (_) =>
                          ref.read(_reviewFilter(courseId).notifier).state =
                              null,
                    ),
                    for (var star = 5; star >= 1; star--)
                      ChoiceChip(
                        label: Text('$star ★ (${page.distribution[star - 1]})'),
                        selected: rating == star,
                        onSelected: (_) =>
                            ref.read(_reviewFilter(courseId).notifier).state =
                                star,
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                if (page.items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: const Center(
                      child: Text('No reviews with this rating yet.'),
                    ),
                  ),
                for (final review in page.items)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review['student_name'] as String,
                                style: AppTextStyles.interSemiBold16,
                              ),
                            ),
                            Text(
                              '${review['rating']} / 5',
                              style: AppTextStyles.interMedium16,
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          (review['created_at'] as String).split('T').first,
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.grey500,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          review['body'] as String,
                          style: AppTextStyles.interRegular14,
                        ),
                        SizedBox(height: 16.h),
                        const Divider(color: AppColors.grey200),
                      ],
                    ),
                  ),
                if (page.error != null)
                  Text(page.error!, textAlign: TextAlign.center),
                if (page.hasMore)
                  Center(
                    child: TextButton(
                      onPressed: page.loadingMore
                          ? null
                          : () => ref.read(provider.notifier).more(),
                      child: page.loadingMore
                          ? SizedBox.square(
                              dimension: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Load more reviews'),
                    ),
                  ),
              ],
            );
          },
        );
  }
}
