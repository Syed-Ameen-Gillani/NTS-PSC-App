import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/repositories/lesson_player_repository_provider.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_resources_sheet.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LessonNotesTab extends ConsumerStatefulWidget {
  final CourseModel course;
  final LessonModel lesson;

  const LessonNotesTab({super.key, required this.course, required this.lesson});

  @override
  ConsumerState<LessonNotesTab> createState() => _LessonNotesTabState();
}

class _LessonNotesTabState extends ConsumerState<LessonNotesTab> {
  final TextEditingController _noteController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSavingNote = false;
  bool _isNoteSaved = true;
  bool _isLessonCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(lessonPlayerRepositoryProvider);
    final note = await repo.getPersonalNote(widget.lesson.id);
    final completed = await repo.isLessonCompleted(
      courseId: widget.course.id,
      lessonId: widget.lesson.id,
    );

    if (mounted) {
      if (note != null && note.content.isNotEmpty) {
        _noteController.text = note.content;
      }
      setState(() {
        _isLessonCompleted = completed;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged(String text) {
    setState(() {
      _isNoteSaved = false;
    });

    // 600ms Debounce to prevent database write storms at 1M+ scale
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isSavingNote = true);
      final repo = ref.read(lessonPlayerRepositoryProvider);
      await repo.savePersonalNote(widget.lesson.id, text);
      if (mounted) {
        setState(() {
          _isSavingNote = false;
          _isNoteSaved = true;
        });
      }
    });
  }

  Future<void> _handleMarkCompleted() async {
    final repo = ref.read(lessonPlayerRepositoryProvider);
    await repo.markLessonCompleted(
      courseId: widget.course.id,
      lessonId: widget.lesson.id,
    );

    ref
        .read(myLearningControllerProvider.notifier)
        .markLessonCompleted(widget.course.id, widget.lesson.id);

    if (mounted) {
      setState(() => _isLessonCompleted = true);
      CustomToast.showSuccess(
        context,
        message: 'Lesson completed! Course progress updated.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Lecture Overview & Course Files
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Lecture Overview',
                  style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton.icon(
                onPressed: () {
                  CourseResourcesSheet.show(
                    context,
                    courseId: widget.course.id,
                    courseTitle: widget.course.title,
                  );
                },
                icon: Icon(
                  Icons.folder_shared_outlined,
                  size: 14.w,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Course Files',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Overview Content Card (matching user's design)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lesson.notes.isNotEmpty
                      ? widget.lesson.notes
                      : 'Structure of AJK Legislative Assembly, Council, and High Court/Supreme Court.',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 13.sp,
                    height: 1.6,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Student Personal Notebook Section (Debounced Auto-save)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note, size: 18.w, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Personal Notebook',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSavingNote) ...[
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Saving...',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ] else if (_isNoteSaved) ...[
                    Icon(Icons.check_circle, size: 12.w, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      'Saved',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 10.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey300),
            ),
            child: TextField(
              onTapOutside: dismissKeyboardOnTapOutside,
              controller: _noteController,
              onChanged: _onNoteChanged,
              maxLines: 4,
              style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp),
              decoration: InputDecoration(
                hintText:
                    'Type your personal notes, constitutional section references, and exam mnemonics here... (auto-saved)',
                hintStyle: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey400,
                ),
                contentPadding: EdgeInsets.all(12.w),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Completion Button
          CustomButton(
            text: _isLessonCompleted
                ? '✓ Lesson Completed'
                : 'Mark Lesson as Completed',
            onPressed: () {
              if (!_isLessonCompleted) {
                _handleMarkCompleted();
              }
            },
            color: _isLessonCompleted
                ? Colors.green.shade600
                : AppColors.primary,
          ),
        ],
      ),
    );
  }
}
