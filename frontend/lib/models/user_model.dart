class UserModel {
  final String collegeId;
  final String name;
  final String gender;
  final String? phone;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.collegeId,
    required this.name,
    required this.gender,
    this.phone,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      collegeId: json['college_id'],
      name: json['name'] ?? json['college_id'],
      gender: json['gender'],
      phone: json['phone'],
      fcmToken: json['fcm_token'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'college_id': collegeId,
    'name': name,
    'gender': gender,
    'phone': phone,
    'fcm_token': fcmToken,
    'created_at': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? fcmToken,
  }) {
    return UserModel(
      collegeId: collegeId,
      name: name ?? this.name,
      gender: gender,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}