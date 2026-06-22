class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? phoneNumber;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.phoneNumber,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? json['title'] as String? ?? '',
      fullAddress: json['full_address'] as String? ??
          json['address'] as String? ??
          '',
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String? ?? json['zip'] as String?,
      country: json['country'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isDefault: json['is_default'] as bool? ?? json['default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'full_address': fullAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zip_code': zipCode,
      if (country != null) 'country': country,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'is_default': isDefault,
    };
  }

  String get displayText {
    final parts = [fullAddress, city, state, zipCode, country]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
