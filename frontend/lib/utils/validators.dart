// College ID validation
class Validators {
  static bool isValidCollegeId(String value) {
    // 🔥 UPDATE THIS REGEX BASED ON YOUR COLLEGE FORMAT
    // Example: 2024CS101 (Year + Dept + Roll)
    final regex = RegExp(r'^[0-9]{4}[A-Z]{2}[0-9]{3}$');
    return regex.hasMatch(value);
  }

  static bool isValidPhone(String value) {
    final regex = RegExp(r'^[0-9]{10}$');
    return regex.hasMatch(value);
  }

  static bool isValidName(String value) {
    return value.isNotEmpty && value.length >= 2;
  }
}