import 'package:nts_psc_app/core/models/app_models.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getFeaturedCourses();
  Future<List<CourseModel>> getContinueLearningCourses(String studentId);
  Future<List<CategoryModel>> getCategories();
  Future<List<CourseModel>> getCoursesByCategory(String? category);
  Future<List<CourseModel>> getNewCourses();
  Future<List<CourseModel>> getEnrolledCourses(String studentId);
  Future<List<CourseModel>> getTeacherCourses(String teacherId);
  Future<CourseModel?> getCourseById(String courseId);
  Future<bool> enrollInCourse(String courseId, String studentId);
  Future<CourseModel> createCourse(CourseModel course);
  Future<bool> updateLessonProgress({
    required String courseId,
    required String lessonId,
    required bool isCompleted,
  });
}
