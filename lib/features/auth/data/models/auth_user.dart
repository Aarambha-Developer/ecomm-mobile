class AuthUser {
  final String id;
  final String email;
  final String? phoneNumber;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';
}
