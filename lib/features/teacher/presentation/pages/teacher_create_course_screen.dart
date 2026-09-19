import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherCreateCourseScreen extends ConsumerStatefulWidget {
  const TeacherCreateCourseScreen({super.key});

  @override
  ConsumerState<TeacherCreateCourseScreen> createState() => _TeacherCreateCourseScreenState();
}

class _TeacherCreateCourseScreenState extends ConsumerState<TeacherCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController(text: 'Rs 2,000');
  final _descriptionController = TextEditingController();
  final _moduleTitleController = TextEditingController(text: 'Module 1: Core Fundamentals');
  final _lessonTitleController = TextEditingController(text: 'Lesson 1: Introduction & Scope');
  final _lessonDurationController = TextEditingController(text: '25');

  String _selectedCategory = 'FPSC';
  final List<String> _categories = ['FPSC', 'AJK PSC', 'NTS', 'CSS / PMS', 'General'];
  bool _isSaving = false;

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
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
      body: SafeArea(
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
                  prefixIcon: Icons.menu_book,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a course title' : null,
                ),

                _buildFieldLabel('Exam Category'),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
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
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),

                _buildFieldLabel('Tuition Price (PKR)'),
                CustomTextFormField(
                  controller: _priceController,
                  hintText: 'e.g. Rs 2,500 or Free',
                  prefixIcon: Icons.monetization_on_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a price' : null,
                ),

                _buildFieldLabel('Course Description & Syllabus Overview'),
                CustomTextFormField(
                  controller: _descriptionController,
                  hintText: 'Explain what topics this course covers and who this preparation is meant for...',
                  maxLines: 3,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please write a brief description' : null,
                ),

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
                  'Add the first section and foundational video lecture to launch the course.',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),

                _buildFieldLabel('Module Title'),
                CustomTextFormField(
                  controller: _moduleTitleController,
                  hintText: 'e.g. Module 1: Constitutional Overview',
                  prefixIcon: Icons.folder_open,
                ),

                _buildFieldLabel('First Lecture Title'),
                CustomTextFormField(
                  controller: _lessonTitleController,
                  hintText: 'e.g. Lecture 01: Introduction',
                  prefixIcon: Icons.play_circle_outline,
                ),

                _buildFieldLabel('Estimated Duration (Minutes)'),
                CustomTextFormField(
                  controller: _lessonDurationController,
                  hintText: 'e.g. 30',
                  prefixIcon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: 36.h),

                // Submit Button
                CustomButton(
                  text: _isSaving ? 'Publishing Course...' : 'Publish Course to Catalog',
                  color: AppColors.primary,
                  onPressed: _isSaving
                      ? () {}
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _isSaving = true);
                            final duration = int.tryParse(_lessonDurationController.text.trim()) ?? 20;

                            final newCourse = CourseModel(
                              id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text.trim(),
                              author: 'Sir Tariq Mahmood',
                              rating: 5.0,
                              price: _priceController.text.trim(),
                              imagePath: AppAssets.course1,
                              category: _selectedCategory,
                              description: _descriptionController.text.trim(),
                              enrolledCount: 0,
                              isPublished: true,
                              modules: [
                                CourseModuleModel(
                                  id: 'm1',
                                  title: _moduleTitleController.text.trim(),
                                  lessons: [
                                    LessonModel(
                                      id: 'l1',
                                      title: _lessonTitleController.text.trim(),
                                      durationMinutes: duration,
                                      notes: 'Study notes will be accessible to enrolled candidates.',
                                    ),
                                  ],
                                ),
                              ],
                            );

                            await ref.read(teacherControllerProvider.notifier).addCourse(newCourse);
                            setState(() => _isSaving = false);

                            if (context.mounted) {
                              CustomToast.showSuccess(
                                context,
                                message: 'Course "${newCourse.title}" published successfully!',
                              );
                              context.pop();
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
    );
  }
}
