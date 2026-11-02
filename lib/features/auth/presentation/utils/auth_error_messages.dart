import 'package:supabase_flutter/supabase_flutter.dart';

String loginErrorMessage(Object? error) {
  final message = _normalized(error);
  if (message.contains('invalid login credentials')) {
    return 'Incorrect email or password.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirm your email before signing in.';
  }
  if (message.contains('registered as a teacher')) {
    return 'Use the teacher login for this account.';
  }
  if (message.contains('registered as a student')) {
    return 'Use the student login for this account.';
  }
  if (_isRateLimited(message)) {
    return 'Too many attempts. Try again shortly.';
  }
  if (_isConnectionError(message)) {
    return 'Check your connection and try again.';
  }
  return 'Could not sign in. Try again.';
}

String signupErrorMessage(Object? error) {
  final message = _normalized(error);
  if (message.contains('already registered') ||
      message.contains('already been registered') ||
      message.contains('user already exists')) {
    return 'An account already exists for this email.';
  }
  if (message.contains('password') &&
      (message.contains('weak') || message.contains('characters'))) {
    return 'Use a stronger password.';
  }
  if (message.contains('invalid email')) {
    return 'Enter a valid email.';
  }
  if (message.contains('signup') && message.contains('disabled')) {
    return 'Account creation is unavailable right now.';
  }
  if (message.contains('confirm email') ||
      message.contains('immediate sign-in')) {
    return 'Check your email to finish signing up.';
  }
  if (_isRateLimited(message)) {
    return 'Too many attempts. Try again shortly.';
  }
  if (_isConnectionError(message)) {
    return 'Check your connection and try again.';
  }
  return 'Could not create your account. Try again.';
}

String socialSignInErrorMessage(Object? error, OAuthProvider provider) {
  final providerName = provider == OAuthProvider.apple ? 'Apple' : 'Google';
  final message = _normalized(error);
  if (message.contains('not configured')) {
    return '$providerName sign-in is not available yet.';
  }
  if (message.contains('web callback')) {
    return '$providerName sign-in is unavailable on web.';
  }
  if (message.contains('open the sign-in page')) {
    return 'Could not open $providerName sign-in.';
  }
  if (_isConnectionError(message)) {
    return 'Check your connection and try again.';
  }
  return '$providerName sign-in failed. Try again.';
}

String _normalized(Object? error) {
  if (error is AuthException) return error.message.toLowerCase();
  if (error is StateError) return error.message.toLowerCase();
  if (error is ArgumentError) return error.message.toString().toLowerCase();
  return error?.toString().toLowerCase() ?? '';
}

bool _isRateLimited(String message) =>
    message.contains('rate limit') || message.contains('too many requests');

bool _isConnectionError(String message) =>
    message.contains('network') ||
    message.contains('socket') ||
    message.contains('connection') ||
    message.contains('clientexception');
