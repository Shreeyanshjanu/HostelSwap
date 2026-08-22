// Password-less login
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Login using College ID + Gender
  Future<Map<String, dynamic>?> login(
    String collegeId,
    String gender,
  ) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('college_id', collegeId)
          .eq('gender', gender)
          .maybeSingle();

      return response;
    } catch (e) {
      print('LOGIN ERROR: $e');
      rethrow;
    }
  }

  // Create a new user
  Future<Map<String, dynamic>> createUser(
    String collegeId,
    String gender,
  ) async {
    try {
      final response = await supabase
          .from('users')
          .insert({
            'college_id': collegeId,
            'gender': gender,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('CREATE USER ERROR: $e');
      rethrow;
    }
  }
}