class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email.';
    }
    // Basic email regex pattern
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name is too short.';
    }
    return null;
  }
}
