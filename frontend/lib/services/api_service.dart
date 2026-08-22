import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final http.Client client = http.Client();

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConfig.healthCheckEndpoint),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send natural language to chatbot
  Future<Map<String, dynamic>> sendChatMessage(String message, String userId) async {
    final response = await client.post(
      Uri.parse(ApiConfig.chatEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send chat message: ${response.statusCode}');
    }
  }

  /// Ask RAG assistant about hostel policies
  Future<Map<String, dynamic>> askRAGQuery(String query) async {
    final response = await client.post(
      Uri.parse(ApiConfig.ragQueryEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get RAG response: ${response.statusCode}');
    }
  }

  /// Show contact number (privacy-preserving)
  Future<Map<String, String>> showContact(
    String requestId,
    String requesterId,
    String applicantId,
  ) async {
    final response = await client.post(
      Uri.parse(ApiConfig.showContactEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'request_id': requestId,
        'requester_id': requesterId,
        'applicant_id': applicantId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'requester_phone': data['requester_phone'] ?? '',
        'applicant_phone': data['applicant_phone'] ?? '',
      };
    } else {
      throw Exception('Failed to show contact: ${response.statusCode}');
    }
  }

  /// Finalize swap (Requester selects applicant)
  Future<void> finalizeSwap(
    String requestId,
    String requesterId,
    String applicantId,
  ) async {
    final response = await client.post(
      Uri.parse(ApiConfig.finalizeSwapEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'request_id': requestId,
        'requester_id': requesterId,
        'applicant_id': applicantId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to finalize swap: ${response.statusCode}');
    }
  }

  /// Withdraw request
  Future<void> withdrawRequest(String requestId) async {
    final response = await client.post(
      Uri.parse(ApiConfig.withdrawRequestEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'request_id': requestId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to withdraw request: ${response.statusCode}');
    }
  }
}