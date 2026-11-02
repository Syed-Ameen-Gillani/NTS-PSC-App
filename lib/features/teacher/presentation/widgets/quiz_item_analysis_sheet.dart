import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/models/course_community_models.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/presentation/widgets/feature_unavailable.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizItemAnalysisSheet extends ConsumerWidget {
  final String quizTitle;
  final QuizModel? quiz;

  const QuizItemAnalysisSheet({super.key, required this.quizTitle, this.quiz});

  static void show(
    BuildContext context, {
    required String quizTitle,
    QuizModel? quiz,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          QuizItemAnalysisSheet(quizTitle: quizTitle, quiz: quiz),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled) {
      final current = quiz;
      if (current == null) {
        return const Material(
          child: SafeArea(
            child: FeatureUnavailable(message: 'Quiz analysis is unavailable.'),
          ),
        );
      }
      return Material(
        color: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: FutureBuilder(
              future: SupabaseQuizRepository(
                Supabase.instance.client,
              ).getTeacherQuizSummary(current.id),
              builder: (context, snapshot) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.title, style: AppTextStyles.interBold24),
                  SizedBox(height: 12.h),
                  Text(
                    '${current.totalQuestions} questions',
                    style: AppTextStyles.interMedium16,
                  ),
                  if (snapshot.hasData) ...[
                    SizedBox(height: 8.h),
                    Text('${snapshot.data!.attempts} attempts'),
                    Text(
                      'Average score: ${snapshot.data!.averagePercent.toStringAsFixed(1)}%',
                    ),
                  ] else if (snapshot.hasError)
                    const Text('Could not load attempt summary.')
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final items = ref.watch(courseCommunityProvider).itemAnalysis;
    final trickyCount = items.where((i) => i.isTricky).length;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.85.sh),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Item Analysis',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      quizTitle,
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '$trickyCount Tricky Qs',
                  style: TextStyle(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildQuestionDiagnosticCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDiagnosticCard(QuizItemAnalysisModel item) {
    final pct = (item.correctPercentage * 100).toInt();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.isTricky ? const Color(0xFFFCA5A5) : AppColors.grey200,
          width: item.isTricky ? 1.5.w : 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: item.isTricky
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                child: Text(
                  '${item.questionNumber}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: item.isTricky
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Success Rate: $pct% (${item.totalAttempts} attempts)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              if (item.isTricky)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Needs Revision',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: item.correctPercentage,
              backgroundColor: AppColors.grey200,
              color: item.isTricky
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            item.questionText,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey800,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14.w,
                      color: AppColors.grey600,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Common Misconception:',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  item.commonDistractor,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '💡 Recommendation: ${item.teacherRecommendation}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
