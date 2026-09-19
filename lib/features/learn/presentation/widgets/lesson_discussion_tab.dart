import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/lesson_player_models.dart';
import 'package:nts_psc_app/core/repositories/lesson_player_repository_provider.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LessonDiscussionTab extends ConsumerStatefulWidget {
  final CourseModel course;
  final LessonModel lesson;

  const LessonDiscussionTab({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  ConsumerState<LessonDiscussionTab> createState() => _LessonDiscussionTabState();
}

class _LessonDiscussionTabState extends ConsumerState<LessonDiscussionTab> {
  final TextEditingController _commentController = TextEditingController();
  List<LessonDiscussionItem> _discussions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    final repo = ref.read(lessonPlayerRepositoryProvider);
    final items = await repo.getDiscussions(widget.lesson.id);
    if (mounted) {
      setState(() {
        _discussions = List.from(items);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handlePostQuestion() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    // Optimistic UI update at 1M+ scale
    final repo = ref.read(lessonPlayerRepositoryProvider);
    final newItem = await repo.postQuestion(
      lessonId: widget.lesson.id,
      question: text,
      studentName: 'Candidate (You)',
    );

    if (mounted) {
      setState(() {
        _discussions.insert(0, newItem);
      });
      CustomToast.showSuccess(context, message: 'Question submitted to instructor!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Doubts / Questions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _discussions.isEmpty
                  ? Center(
                      child: Text(
                        'No questions posted yet. Be the first to ask!',
                        style: AppTextStyles.interMedium16.copyWith(fontSize: 13.sp, color: AppColors.grey500),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      itemCount: _discussions.length,
                      separatorBuilder: (_, __) => SizedBox(height: 14.h),
                      itemBuilder: (context, index) {
                        final doubt = _discussions[index];
                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12.r,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          doubt.studentInitial,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(doubt.studentName,
                                          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp)),
                                    ],
                                  ),
                                  Text(doubt.timeAgo,
                                      style: AppTextStyles.interRegular14.copyWith(fontSize: 10.sp, color: AppColors.grey500)),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(doubt.question,
                                  style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.onBackground)),
                              if (doubt.isResolved && doubt.instructorReply != null) ...[
                                SizedBox(height: 10.h),
                                Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.verified, size: 12.w, color: AppColors.primary),
                                          SizedBox(width: 4.w),
                                          Text(doubt.instructorName ?? 'Instructor Reply:',
                                              style: AppTextStyles.interSemiBold16
                                                  .copyWith(fontSize: 11.sp, color: AppColors.primary)),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(doubt.instructorReply!,
                                          style: AppTextStyles.interRegular14
                                              .copyWith(fontSize: 11.sp, color: AppColors.onBackground)),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SizedBox(height: 6.h),
                                Text('● Pending Instructor Reply',
                                    style: AppTextStyles.interMedium16
                                        .copyWith(fontSize: 10.sp, color: Colors.orange.shade800)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),

        // Bottom Ask Question Input Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey300, width: 1.w)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Ask the instructor a question...',
                    hintStyle: AppTextStyles.interRegular14.copyWith(fontSize: 13.sp, color: AppColors.grey400),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    filled: true,
                    fillColor: AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _handlePostQuestion(),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                onPressed: _handlePostQuestion,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
