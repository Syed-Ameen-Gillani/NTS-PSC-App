import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/student_analytics_header.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/student_performance_sheet.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  final String? initialCourseTitle;

  const TeacherStudentsScreen({super.key, this.initialCourseTitle});

  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late String _selectedCourse;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.initialCourseTitle ?? 'All Courses';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);

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
          'Learner Analytics & Roster',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: AppColors.onBackground),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            // Extract distinct courses
            final availableCourses = [
              'All Courses',
              ...state.students.map((s) => s.courseTitle).toSet(),
            ];

            // Filter students
            final filteredStudents = state.students.where((st) {
              final query = _searchQuery.toLowerCase();
              final matchesSearch = st.name.toLowerCase().contains(query) ||
                  st.email.toLowerCase().contains(query) ||
                  st.courseTitle.toLowerCase().contains(query);

              final matchesCourse = _selectedCourse == 'All Courses' || st.courseTitle == _selectedCourse;

              final matchesStatus = _selectedStatus == 'All' || st.status == _selectedStatus;

              return matchesSearch && matchesCourse && matchesStatus;
            }).toList();

            return ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                // Search Bar
                CustomTextFormField(
                  controller: _searchController,
                  hintText: 'Search learners by name or email...',
                  prefixIcon: Icons.search,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                SizedBox(height: 14.h),

                // Course Selection Horizontal Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableCourses.map((course) {
                      final isSelected = _selectedCourse == course;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(course),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCourse = course),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF8F9FA),
                          labelStyle: AppTextStyles.interMedium16.copyWith(
                            fontSize: 11.sp,
                            color: isSelected ? Colors.white : AppColors.grey700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10.h),

                // Status Filter Chips (Coursera Learner Success Status)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'On Track', 'Needs Attention', 'Completed'].map((status) {
                      final isSelected = _selectedStatus == status;
                      final count = status == 'All'
                          ? state.students.where((s) => _selectedCourse == 'All Courses' || s.courseTitle == _selectedCourse).length
                          : state.students.where((s) => (_selectedCourse == 'All Courses' || s.courseTitle == _selectedCourse) && s.status == status).length;

                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: Text('$status ($count)'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedStatus = status),
                          selectedColor: status == 'Needs Attention'
                              ? const Color(0xFFFEF3C7)
                              : AppColors.primary.withValues(alpha: 0.12),
                          backgroundColor: Colors.white,
                          labelStyle: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 11.sp,
                            color: isSelected
                                ? (status == 'Needs Attention' ? const Color(0xFFB45309) : AppColors.primary)
                                : AppColors.grey500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(
                              color: isSelected
                                  ? (status == 'Needs Attention' ? const Color(0xFFD97706) : AppColors.primary)
                                  : AppColors.grey300,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16.h),

                // Coursera Executive Summary Cards
                StudentAnalyticsHeader(students: filteredStudents),
                SizedBox(height: 18.h),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Enrolled Learners (${filteredStudents.length})',
                        style: AppTextStyles.interBold24.copyWith(fontSize: 15.sp, color: AppColors.onBackground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Tap card for diagnostics',
                      style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Student Cards List
                if (filteredStudents.isEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 48.h),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48.w, color: AppColors.grey400),
                        SizedBox(height: 12.h),
                        Text(
                          'No learners found matching filters.',
                          style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredStudents.map((student) => _buildStudentCard(context, student)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading learner analytics')),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentRosterModel student) {
    final isAtRisk = student.status == 'Needs Attention';
    final isCompleted = student.status == 'Completed';

    Color statusColor;
    Color statusBgColor;
    if (isAtRisk) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
    } else if (isCompleted) {
      statusColor = const Color(0xFF2563EB);
      statusBgColor = const Color(0xFFDBEAFE);
    } else {
      statusColor = const Color(0xFF059669);
      statusBgColor = const Color(0xFFD1FAE5);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isAtRisk ? const Color(0xFFFCD34D) : AppColors.grey300,
          width: isAtRisk ? 1.5.w : 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => StudentPerformanceSheet.show(context, student),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name, Email, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'S',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  student.name,
                                  style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  student.status,
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 9.sp,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            student.email,
                            style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: student.averageQuizScore >= 60 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        '${student.averageQuizScore}% Quiz',
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 10.sp,
                          color: student.averageQuizScore >= 60 ? const Color(0xFF065F46) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Course title
                Text(
                  student.courseTitle,
                  style: AppTextStyles.interMedium16.copyWith(fontSize: 11.sp, color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // Progress Bar & Lessons
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: student.progress,
                          backgroundColor: AppColors.grey300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAtRisk ? const Color(0xFFD97706) : AppColors.primary,
                          ),
                          minHeight: 6.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${student.completedLessons}/${student.totalLessons} Lessons (${(student.progress * 100).toInt()}%)',
                      style: AppTextStyles.interMedium16.copyWith(fontSize: 11.sp, color: AppColors.grey700),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Bottom Row: Active time & Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 12.w, color: AppColors.grey500),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              'Active ${student.lastActive}',
                              style: AppTextStyles.interRegular14.copyWith(fontSize: 10.sp, color: AppColors.grey500),
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
                        if (student.lastNudgedAt != null)
                          Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Icon(Icons.notifications_active, size: 14.w, color: AppColors.success),
                          ),
                        Text(
                          'View Diagnostics →',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
