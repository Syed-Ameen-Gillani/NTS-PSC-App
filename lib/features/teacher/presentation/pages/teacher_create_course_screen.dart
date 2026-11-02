import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/data/course_cover_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/draft_course_cover_picker.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_pricing_field.dart';
import 'package:nts_psc_app/features/curriculum/domain/course_pricing.dart';

final _draftBusyProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);
final _draftCategoryProvider = StateProvider.autoDispose.family<String, String>(
  (ref, id) => 'FPSC',
);

class TeacherCreateCourseScreen extends ConsumerStatefulWidget {
  const TeacherCreateCourseScreen({super.key});

  @override
  ConsumerState<TeacherCreateCourseScreen> createState() =>
      _TeacherCreateCourseScreenState();
}

class _TeacherCreateCourseScreenState
    extends ConsumerState<TeacherCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _draftId = const Uuid().v4();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _moduleTitleController = TextEditingController(
    text: AppConfig.isSupabaseEnabled ? '' : 'Module 1: Core Fundamentals',
  );
  final _lessonTitleController = TextEditingController(
    text: AppConfig.isSupabaseEnabled ? '' : 'Lesson 1: Introduction & Scope',
  );
  final _lessonDurationController = TextEditingController(text: '25');

  String get _selectedCategory => ref.read(_draftCategoryProvider(_draftId));
  final List<String> _categories = [
    'FPSC',
    'AJK PSC',
    'NTS',
    'CSS / PMS',
    'General',
  ];
  bool get _isSaving => ref.read(_draftBusyProvider(_draftId));

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _moduleTitleController.dispose();
    _lessonTitleController.dispose();
    _lessonDurationController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 14.h),
      child: Text(
        text,
        style: AppTextStyles.interSemiBold16.copyWith(
          color: AppColors.onBackground,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_draftBusyProvider(_draftId));
    ref.watch(_draftCategoryProvider(_draftId));
    return PopScope(
      canPop: !_isSaving,
      child: AppScaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.onBackground,
              size: 20,
            ),
            onPressed: _isSaving ? null : () => context.pop(),
          ),
          title: Text(
            'Create New Course',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Container(color: AppColors.grey300, height: 1.h),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _isSaving,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Details',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Set up your course overview, exam category, and tuition pricing.',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),

                    _buildFieldLabel('Course Title'),
                    CustomTextFormField(
                      controller: _titleController,
                      hintText: 'e.g. FPSC Preventive Officer Complete Guide',
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.menu_book,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter a course title'
                          : null,
                    ),

                    _buildFieldLabel('Exam Category'),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 1.w,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppColors.background,
                          focusColor: AppColors.surface,
                          iconEnabledColor: AppColors.grey600,
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: AppTextStyles.interMedium16.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                      .read(
                                        _draftCategoryProvider(
                                          _draftId,
                                        ).notifier,
                                      )
                                      .state =
                                  val;
                            }
                          },
                        ),
                      ),
                    ),

                    CoursePricingField(
                      draftId: _draftId,
                      controller: _priceController,
                    ),

                    _buildFieldLabel('Course Description & Syllabus Overview'),
                    CustomTextFormField(
                      controller: _descriptionController,
                      hintText:
                          'Explain what topics this course covers and who this preparation is meant for...',
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please write a brief description'
                          : null,
                    ),

                    if (AppConfig.isSupabaseEnabled) ...[
                      _buildFieldLabel('Course Cover'),
                      DraftCourseCoverPicker(
                        draftId: _draftId,
                        busy: _isSaving,
                      ),
                    ],

                    SizedBox(height: 24.h),
                    Divider(color: AppColors.grey300, thickness: 1.h),
                    SizedBox(height: 16.h),

                    // Initial Module & Lesson Setup
                    Text(
                      'Initial Curriculum Module',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Add the first module and lesson to your course draft.',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),

                    _buildFieldLabel('Module Title'),
                    CustomTextFormField(
                      controller: _moduleTitleController,
                      hintText: 'e.g. Module 1: Constitutional Overview',
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.folder_open,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter a module title'
                          : null,
                    ),

                    _buildFieldLabel('First Lecture Title'),
                    CustomTextFormField(
                      controller: _lessonTitleController,
                      hintText: 'e.g. Lecture 01: Introduction',
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.play_circle_outline,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter a lesson title'
                          : null,
                    ),

                    _buildFieldLabel('Estimated Duration (Minutes)'),
                    CustomTextFormField(
                      controller: _lessonDurationController,
                      hintText: 'e.g. 30',
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          (int.tryParse(value?.trim() ?? '') ?? 0) <= 0
                          ? 'Enter a duration above zero'
                          : null,
                    ),
                    SizedBox(height: 36.h),

                    // Submit Button
                    CustomButton(
                      text: _isSaving ? 'Saving Draft...' : 'Create Draft',
                      color: AppColors.primary,
                      onPressed: _isSaving
                          ? () {}
                          : () async {
                              final formIsValid =
                                  _formKey.currentState?.validate() ?? false;
                              final cover = ref.read(
                                draftCourseCoverProvider(_draftId),
                              );
                              final coverIsValid =
                                  !AppConfig.isSupabaseEnabled || cover != null;
                              ref
                                      .read(
                                        draftCourseCoverErrorProvider(
                                          _draftId,
                                        ).notifier,
                                      )
                                      .state =
                                  !coverIsValid;
                              if (formIsValid && coverIsValid) {
                                ref
                                        .read(
                                          _draftBusyProvider(_draftId).notifier,
                                        )
                                        .state =
                                    true;
                                final duration =
                                    int.tryParse(
                                      _lessonDurationController.text.trim(),
                                    ) ??
                                    20;

                                final newCourse = CourseModel(
                                  id: _draftId,
                                  title: _titleController.text.trim(),
                                  author: AppConfig.isSupabaseEnabled
                                      ? ref
                                                .read(authControllerProvider)
                                                .value
                                                ?.user
                                                ?.name ??
                                            ''
                                      : 'Sir Tariq Mahmood',
                                  rating: AppConfig.isSupabaseEnabled ? 0 : 5.0,
                                  price: CoursePricing.label(
                                    ref.read(paidCourseDraftProvider(_draftId))
                                        ? CoursePricing.parsePaidAmount(
                                            _priceController.text,
                                          )!
                                        : 0,
                                  ),
                                  priceAmount:
                                      ref.read(
                                        paidCourseDraftProvider(_draftId),
                                      )
                                      ? CoursePricing.parsePaidAmount(
                                          _priceController.text,
                                        )!
                                      : 0,
                                  imagePath: AppAssets.course1,
                                  category: _selectedCategory,
                                  description: _descriptionController.text
                                      .trim(),
                                  enrolledCount: 0,
                                  isPublished: false,
                                  modules: [
                                    CourseModuleModel(
                                      id: 'm1',
                                      title: _moduleTitleController.text.trim(),
                                      lessons: [
                                        LessonModel(
                                          id: 'l1',
                                          title: _lessonTitleController.text
                                              .trim(),
                                          durationMinutes: duration,
                                          notes: AppConfig.isSupabaseEnabled
                                              ? ''
                                              : 'Study notes will be accessible to enrolled candidates.',
                                        ),
                                      ],
                                    ),
                                  ],
                                );

                                try {
                                  var created = await ref
                                      .read(teacherControllerProvider.notifier)
                                      .addCourse(newCourse);
                                  if (!mounted) return;
                                  String message = 'Course draft saved.';
                                  var coverFailed = false;
                                  if (cover != null &&
                                      AppConfig.isSupabaseEnabled) {
                                    try {
                                      final coverUrl = await ref
                                          .read(courseCoverRepositoryProvider)
                                          .upload(created.id, cover.bytes);
                                      created = created.copyWith(
                                        coverUrl: coverUrl,
                                      );
                                      ref
                                          .read(
                                            teacherControllerProvider.notifier,
                                          )
                                          .updateCourseCover(
                                            created.id,
                                            coverUrl,
                                          );
                                      message = 'Draft and cover saved.';
                                    } catch (_) {
                                      coverFailed = true;
                                      message =
                                          'Draft saved. Add the cover from course management.';
                                    }
                                  }
                                  if (context.mounted) {
                                    if (coverFailed) {
                                      CustomToast.showError(
                                        context,
                                        message: message,
                                      );
                                    } else {
                                      CustomToast.showSuccess(
                                        context,
                                        message: message,
                                      );
                                    }
                                    context.pushReplacementNamed(
                                      AppRoute.teacherManageCourse.name,
                                      extra: created,
                                    );
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    CustomToast.showError(
                                      context,
                                      message: error is PostgrestException
                                          ? error.message
                                          : 'Could not save the draft. Please retry.',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    ref
                                            .read(
                                              _draftBusyProvider(
                                                _draftId,
                                              ).notifier,
                                            )
                                            .state =
                                        false;
                                  }
                                }
                              }
                            },
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
