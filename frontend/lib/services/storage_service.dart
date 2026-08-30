import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _collegeIdKey = 'college_id';
  static const String _genderKey = 'gender';
  static const String _nameKey = 'name';

  Future<void> saveUser(String collegeId, String gender, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collegeIdKey, collegeId);
    await prefs.setString(_genderKey, gender);
    if (name != null) await prefs.setString(_nameKey, name);
  }

  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_collegeIdKey);
    final gender = prefs.getString(_genderKey);
    if (id != null && gender != null) {
      return {
        'collegeId': id,
        'gender': gender,
        'name': prefs.getString(_nameKey) ?? id,
      };
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collegeIdKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_nameKey);
  }
}