// lib/providers/request_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_provider.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

final requestServiceProvider = Provider((ref) => SupabaseService());

// 🔥 CHANGED: Use a record instead of Map for stable equality
final requestProvider = FutureProvider.family<List<RequestModel>, ({
  String? hostel,
  bool? ac,
  int? seater,
})>((ref, filters) async {
  final service = ref.read(requestServiceProvider);
  final user = ref.read(authProvider);
  
  return await service.getRequests(
    hostel: filters.hostel,
    ac: filters.ac,
    seater: filters.seater,
    gender: user?.gender,
    userId: user?.collegeId,
  );
});

final userRequestsProvider = FutureProvider.family<List<RequestModel>, String>((ref, userId) async {
  final service = ref.read(requestServiceProvider);
  return await service.getUserRequests(userId);
});

final createRequestProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final service = ref.read(requestServiceProvider);
  await service.createRequest(data);
});