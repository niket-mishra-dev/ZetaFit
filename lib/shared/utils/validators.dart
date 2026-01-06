// lib/core/utils/validators.dart

class Validators {
  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    const pattern =
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    if (!RegExp(pattern).hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  /// Validate password strength
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < minLength) {
      return "Password must be at least $minLength characters";
    }
    return null;
  }

  /// Validate non-empty fields
  static String? required(String? value, {String field = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$field is required";
    }
    return null;
  }

  /// Validate username
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Username is required";
    }
    if (value.length < 3) {
      return "Username must be at least 3 characters";
    }
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";

    const pattern = r'^[0-9]{7,15}$';
    if (!RegExp(pattern).hasMatch(value)) {
      return "Enter a valid phone number";
    }
    return null;
  }

  /// Validate numeric fields
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return "Number is required";
    }
    if (double.tryParse(value) == null) {
      return "Enter a valid number";
    }
    return null;
  }
}
