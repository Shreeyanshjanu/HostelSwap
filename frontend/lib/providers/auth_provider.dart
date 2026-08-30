import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
//  removed: import 'package:flutter_riverpod/legacy.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider((ref) => SupabaseService());
final storageServiceProvider = Provider((ref) => StorageService());

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final SupabaseService _supabaseService;
  final StorageService _storageService;

  AuthNotifier(this._supabaseService, this._storageService) : super(null) {
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      final user = await _supabaseService.getUser(userData['collegeId']!);
      if (user != null) {
        state = user;
        // 🔥 Skip FCM in auto-login too
        try {
          final fcmService = FCMService();
          final token = await fcmService.getToken().timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
          if (token != null) {
            await _supabaseService.updateUserToken(user.collegeId, token);
            state = state?.copyWith(fcmToken: token);
          }
        } catch (e) {
          print(' FCM auto-login error: $e');
        }
      }
    }
  }

  Future<UserModel?> login(
    String collegeId,
    String gender, {
    String? name,
  }) async {
    try {
      print('1. Starting login...');
      var user = await _supabaseService.getUser(collegeId);
      print('2. getUser completed: $user');
      if (user == null) {
        print('3. User not found. Creating user...');
        user = await _supabaseService.createUser(collegeId, gender, name: name);
        print('4. User created: $user');
      } else {
        print('3. User found: $user');
      }
      print('5. Saving user to storage...');
      await _storageService.saveUser(collegeId, gender, name: user.name);
      print('6. Saved to storage');

      // 🔥 FCM token – skip if it fails
      try {
        final fcmService = FCMService();
        final token = await fcmService.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⏰ FCM token timeout – skipping');
            return null;
          },
        );
        print('7. FCM token: $token');
        if (token != null) {
          await _supabaseService.updateUserToken(collegeId, token);
          user = user.copyWith(fcmToken: token);
        }
      } catch (e) {
        print(' FCM error: $e – continuing without token');
      }

      state = user;
      print('8. Login SUCCESS');
      return user;
    } catch (e) {
      print(' AUTH ERROR: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.clearUser();
    state = null;
  }
}
