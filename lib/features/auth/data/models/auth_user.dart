class AuthUser {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? fullName;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.fullName,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      fullName: json['full_name'] as String? ?? json['name'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (fullName != null) 'full_name': fullName,
    };
  }

  bool get isAdmin => role == 'admin';
}
