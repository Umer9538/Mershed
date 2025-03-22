class Validator {
  /// Validates an email address.
  /// Returns null if valid, otherwise returns an error message.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email';
    }
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates a password.
  /// Returns null if valid, otherwise returns an error message.
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that two fields match (e.g., password confirmation).
  /// Returns null if they match, otherwise returns an error message.
  static String? validateMatch(String? value, String? compareValue, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    if (value.trim() != compareValue?.trim()) {
      return '$fieldName does not match';
    }
    return null;
  }
}