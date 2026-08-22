import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/interest_model.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ============ USERS ============
  Future<UserModel?> getUser(String collegeId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('college_id', collegeId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('GET USER ERROR: $e');
      rethrow;
    }
  }

  Future<UserModel> createUser(String collegeId, String gender) async {
    final response = await supabase
        .from('users')
        .insert({'college_id': collegeId, 'name': collegeId, 'gender': gender})
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  Future<void> updateUserToken(String collegeId, String fcmToken) async {
    await supabase
        .from('users')
        .update({'fcm_token': fcmToken})
        .eq('college_id', collegeId);
  }

  // ============ REQUESTS ============
  Future<List<RequestModel>> getRequests({
    String? hostel,
    bool? ac,
    int? seater,
    String? gender,
    String? userId,
  }) async {
    try {
      var query = supabase.from('requests').select('*').eq('status', 'active');

      // Gender filter
      if (gender == 'male') {
        query = query.inFilter('desired_hostel', ['BH-1', 'BH-2', 'BH-3']);
      } else if (gender == 'female') {
        query = query.inFilter('desired_hostel', ['GH-1', 'GH-2', 'GH-3']);
      }

      // Additional filters
      if (hostel != null && hostel.isNotEmpty) {
        query = query.eq('desired_hostel', hostel);
      }
      if (ac != null) {
        query = query.eq('desired_ac', ac);
      }
      if (seater != null && seater > 0) {
        query = query.eq('desired_seater', seater);
      }

      final response = await query.order('created_at', ascending: false);

      List<RequestModel> requests = [];
      for (var json in response as List) {
        requests.add(RequestModel.fromJson(json));
      }

      // Check if user has applied to each request
      if (userId != null) {
        for (var i = 0; i < requests.length; i++) {
          final hasApplied = await hasAppliedToRequest(requests[i].id, userId);
          requests[i] = RequestModel(
            id: requests[i].id,
            userId: requests[i].userId,
            currentHostel: requests[i].currentHostel,
            currentAc: requests[i].currentAc,
            currentSeater: requests[i].currentSeater,
            desiredHostel: requests[i].desiredHostel,
            desiredAc: requests[i].desiredAc,
            desiredSeater: requests[i].desiredSeater,
            status: requests[i].status,
            createdAt: requests[i].createdAt,
            hasApplied: hasApplied,
          );
        }
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  Future<List<RequestModel>> getUserRequests(String userId) async {
    try {
      final response = await supabase
          .from('requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RequestModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user requests: $e');
    }
  }

  Future<RequestModel> createRequest(Map<String, dynamic> data) async {
    final response = await supabase
        .from('requests')
        .insert(data)
        .select()
        .single();

    return RequestModel.fromJson(response);
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await supabase
        .from('requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<void> deleteRequest(String requestId) async {
    await supabase.from('requests').delete().eq('id', requestId);
  }

  // ============ INTERESTS ============
  Future<void> expressInterest(String requestId, String applicantId) async {
    await supabase.from('interests').insert({
      'request_id': requestId,
      'applicant_id': applicantId,
      'status': 'pending',
    });
  }

  Future<bool> hasAppliedToRequest(String requestId, String userId) async {
    try {
      final response = await supabase
          .from('interests')
          .select('id')
          .eq('request_id', requestId)
          .eq('applicant_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<InterestModel>> getApplicants(String requestId) async {
    try {
      final response = await supabase
          .from('interests')
          .select('*, users(*)')
          .eq('request_id', requestId)
          .eq('status', 'pending');

      return (response as List)
          .map((json) => InterestModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch applicants: $e');
    }
  }

  Future<void> updateInterestStatus(String interestId, String status) async {
    await supabase
        .from('interests')
        .update({'status': status})
        .eq('id', interestId);
  }

  Future<void> rejectAllOtherInterests(
    String requestId,
    String excludeInterestId,
  ) async {
    await supabase
        .from('interests')
        .update({'status': 'rejected'})
        .eq('request_id', requestId)
        .neq('id', excludeInterestId);
  }

  // ============ REALTIME SUBSCRIPTIONS ============
  void subscribeToRequests({
    required Function(List<RequestModel>) onUpdate,
    String? gender,
    String? userId,
  }) {
    var query = supabase
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'active');

    if (gender == 'male') {
      query = query.inFilter('desired_hostel', ['BH-1', 'BH-2', 'BH-3']);
    } else if (gender == 'female') {
      query = query.inFilter('desired_hostel', ['GH-1', 'GH-2', 'GH-3']);
    }

    query.listen((data) async {
      List<RequestModel> requests = [];
      for (var json in data) {
        requests.add(RequestModel.fromJson(json));
      }

      // Check applied status
      if (userId != null) {
        for (var i = 0; i < requests.length; i++) {
          final hasApplied = await hasAppliedToRequest(requests[i].id, userId);
          requests[i] = RequestModel(
            id: requests[i].id,
            userId: requests[i].userId,
            currentHostel: requests[i].currentHostel,
            currentAc: requests[i].currentAc,
            currentSeater: requests[i].currentSeater,
            desiredHostel: requests[i].desiredHostel,
            desiredAc: requests[i].desiredAc,
            desiredSeater: requests[i].desiredSeater,
            status: requests[i].status,
            createdAt: requests[i].createdAt,
            hasApplied: hasApplied,
          );
        }
      }

      onUpdate(requests);
    });
  }
}
