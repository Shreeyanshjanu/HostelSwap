// Riverpod - Interests state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_provider.dart';
import '../models/interest_model.dart';
import '../services/supabase_service.dart';

final interestServiceProvider = Provider((ref) => SupabaseService());

final interestProvider = FutureProvider.family<bool, String>((ref, requestId) async {
  final service = ref.read(interestServiceProvider);
  final user = ref.read(authProvider);
  if (user == null) return false;
  return await service.hasAppliedToRequest(requestId, user.collegeId);
});

final applicantsProvider = FutureProvider.family<List<InterestModel>, String>((ref, requestId) async {
  final service = ref.read(interestServiceProvider);
  return await service.getApplicants(requestId);
});

final expressInterestProvider = FutureProvider.family<void, Map<String, String>>((ref, data) async {
  final service = ref.read(interestServiceProvider);
  await service.expressInterest(data['requestId']!, data['applicantId']!);
});