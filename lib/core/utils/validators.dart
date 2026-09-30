class Validators {
  static final RegExp _rollNumberRegex =
      RegExp(r'^[0-9]{2}(BCM|BDS|BCT|BIT)[0-9]{3}$');

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your roll number';
    }
    final clean = value.trim().toUpperCase();
    if (!_rollNumberRegex.hasMatch(clean)) {
      return 'Format must be: 2 digits + Course (BCM/BDS/BCT/BIT) + 3 digits (e.g. 25BCM539)';
    }
    return null;
  }

  static String? validateCourseMatch({
    required String? rollNumber,
    required String? selectedCourseCode,
  }) {
    if (rollNumber == null || rollNumber.trim().isEmpty) {
      return null;
    }
    if (selectedCourseCode == null || selectedCourseCode.trim().isEmpty) {
      return 'Please select your course';
    }

    final cleanRoll = rollNumber.trim().toUpperCase();
    if (!_rollNumberRegex.hasMatch(cleanRoll)) {
      return null; // Format error will be caught by validateRollNumber
    }

    // Extract course code from roll number (e.g., 25BCM539 -> BCM)
    final match = _rollNumberRegex.firstMatch(cleanRoll);
    final embeddedCourse = match?.group(1);

    if (embeddedCourse != null &&
        embeddedCourse != selectedCourseCode.trim().toUpperCase()) {
      return 'Roll number course ($embeddedCourse) does not match selected course ($selectedCourseCode)';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateWastePortions({
    required num? prepared,
    required num? served,
    required num? wasted,
    int? attendance,
  }) {
    if (prepared == null || prepared < 0) {
      return 'Prepared portions must be 0 or greater';
    }
    if (served == null || served < 0) {
      return 'Served portions must be 0 or greater';
    }
    if (wasted == null || wasted < 0) {
      return 'Wasted portions must be 0 or greater';
    }
    if (attendance != null && attendance < 0) {
      return 'Actual attendance must be 0 or greater';
    }
    if (served + wasted > prepared) {
      return 'Served + wasted portions cannot exceed prepared portions';
    }
    return null;
  }
}
