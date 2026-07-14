class LoginRequest {
  LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterCustomerRequest {
  RegisterCustomerRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'confirmPassword': confirmPassword,
  };
}

class AuthUser {
  AuthUser({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String token;
  final DateTime? expiresAt;
  final String userId;
  final String fullName;
  final String email;
  final String role;

  bool get isExpired =>
      expiresAt == null || !expiresAt!.toUtc().isAfter(DateTime.now().toUtc());

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'].toString()),
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiresAt': expiresAt?.toIso8601String(),
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'role': role,
  };
}
