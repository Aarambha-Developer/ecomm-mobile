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
    String asString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        for (final key in ['full_name', 'name', 'email', 'title', 'value']) {
          final nested = value[key];
          if (nested is String && nested.isNotEmpty) return nested;
        }
      }
      return value.toString();
    }

    String? asNullableString(dynamic value) {
      final text = asString(value).trim();
      return text.isEmpty ? null : text;
    }

    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: asString(json['email']),
      phoneNumber: asNullableString(json['phone_number']),
      fullName: asNullableString(json['full_name'] ?? json['name']),
      role: asNullableString(json['role']) ?? 'user',
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    bool clearPhone = false,
    String? fullName,
    bool clearFullName = false,
    String? role,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: clearPhone ? null : (phoneNumber ?? this.phoneNumber),
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      role: role ?? this.role,
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
