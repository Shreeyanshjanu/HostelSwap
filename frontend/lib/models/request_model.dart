class RequestModel {
  final String id;
  final String userId;
  final String currentHostel;
  final bool currentAc;
  final int currentSeater;
  final String desiredHostel;
  final bool? desiredAc;
  final int? desiredSeater;
  final String status; // 'active', 'matched', 'withdrawn'
  final DateTime createdAt;
  final bool hasApplied;

  RequestModel({
    required this.id,
    required this.userId,
    required this.currentHostel,
    required this.currentAc,
    required this.currentSeater,
    required this.desiredHostel,
    this.desiredAc,
    this.desiredSeater,
    required this.status,
    required this.createdAt,
    this.hasApplied = false,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      userId: json['user_id'],
      currentHostel: json['current_hostel'],
      currentAc: json['current_ac'] ?? false,
      currentSeater: json['current_seater'] ?? 2,
      desiredHostel: json['desired_hostel'],
      desiredAc: json['desired_ac'],
      desiredSeater: json['desired_seater'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      hasApplied: json['has_applied'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'current_hostel': currentHostel,
    'current_ac': currentAc,
    'current_seater': currentSeater,
    'desired_hostel': desiredHostel,
    'desired_ac': desiredAc,
    'desired_seater': desiredSeater,
    'status': status,
  };

  String get roomDisplay => '$currentHostel | ${currentAc ? "AC" : "Non-AC"} | ${currentSeater}-Seater';
  String get desiredDisplay {
    String result = desiredHostel;
    if (desiredAc != null) result += ' | ${desiredAc! ? "AC" : "Non-AC"}';
    if (desiredSeater != null) result += ' | ${desiredSeater!}-Seater';
    return result;
  }
}