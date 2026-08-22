import 'package:frontend/models/user_model.dart';

class InterestModel {
  final String id;
  final String requestId;
  final String applicantId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final UserModel? applicant;

  InterestModel({
    required this.id,
    required this.requestId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    this.applicant,
  });

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['id'],
      requestId: json['request_id'],
      applicantId: json['applicant_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      applicant: json['users'] != null ? UserModel.fromJson(json['users']) : null,
    );
  }
}