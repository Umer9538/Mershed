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

  /// Validates a phone number (e.g., +923001234567).
  /// Returns null if valid, otherwise returns an error message.
  static String? validateRequiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    // Regular expression for phone number (international format with +)
    final phoneRegex = RegExp(r'^\+\d{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g., +923001234567)';
    }
    return null;
  }

  /// Validates a non-empty text field (e.g., destination, name).
  /// Returns null if valid, otherwise returns an error message.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    return null;
  }

  /// Validates a numeric field (e.g., budget).
  /// Returns null if valid, otherwise returns an error message.
  static String? validateNumber(String? value, String fieldName, {double minValue = 0}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number for $fieldName';
    }
    if (number < minValue) {
      return '$fieldName must be at least $minValue';
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

  /// Validates an OTP code (e.g., 6 digits).
  /// Returns null if valid, otherwise returns an error message.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an OTP';
    }
    if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }
}