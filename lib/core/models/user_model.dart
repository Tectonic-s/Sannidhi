enum UserRole {
  devotee,
  staff,
  admin;

  static UserRole fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      case 'devotee':
      default:
        return UserRole.devotee;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.devotee:
        return 'devotee';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Temple Admin';
      case UserRole.staff:
        return 'Gate Verifier (Staff)';
      case UserRole.devotee:
        return 'Devotee';
    }
  }

  String get displayNameTamil {
    switch (this) {
      case UserRole.admin:
        return 'கோயில் நிர்வாகி';
      case UserRole.staff:
        return 'வாயில் சரிபார்ப்பாளர்';
      case UserRole.devotee:
        return 'பக்தர்';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
  });

  bool get isDevotee => role == UserRole.devotee;
  bool get isStaff => role == UserRole.staff;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Devotee',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toDbString(),
        if (token != null) 'token': token,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}
