enum UserRole {
  student,
  teacher,
  guest;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.guest:
        return 'Guest';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.student;
    switch (role.toLowerCase().trim()) {
      case 'teacher':
      case 'instructor':
        return UserRole.teacher;
      case 'guest':
        return UserRole.guest;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}
