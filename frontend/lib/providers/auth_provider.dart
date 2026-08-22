// Riverpod - User state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/fcm_service.dart';

final authServiceProvider = Provider((ref) => SupabaseService());

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final SupabaseService _supabaseService;

  AuthNotifier(this._supabaseService) : super(null);

  Future<UserModel?> login(String collegeId, String gender) async {
    try {
      print('1. Starting login...');

      // Get existing user from Supabase
      print('2. Getting user from Supabase...');
      var user = await _supabaseService.getUser(collegeId);

      print('3. getUser completed: $user');

      // If user doesn't exist, create a new user
      if (user == null) {
        print('4. User not found. Creating user...');

        user = await _supabaseService.createUser(collegeId, gender);

        print('5. User created: $user');
      }

      // FCM should NOT prevent login from succeeding
      try {
        print('6. Getting FCM token...');

        final fcmService = FCMService();

        final token = await fcmService.getToken().timeout(
          const Duration(seconds: 5),
        );

        print('7. FCM token: $token');

        if (token != null) {
          print('8. Updating FCM token...');

          await _supabaseService.updateUserToken(collegeId, token);

          user = user.copyWith(fcmToken: token);

          print('9. FCM token updated');
        }
      } catch (e) {
        // FCM failure should NOT stop login
        print('FCM skipped: $e');
      }

      // Save user in Riverpod state
      print('10. Setting auth state...');

      state = user;

      print('11. LOGIN SUCCESS');

      return user;
    } catch (e) {
      print('AUTH ERROR: $e');
      return null;
    }
  }

  void logout() {
    state = null;
  }
}
