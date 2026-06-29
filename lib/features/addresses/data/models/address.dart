class Address {
  final String id;
  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String municipality;
  final String street;
  final String? zipCode;
  final String label;
  final bool isDefault;

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.municipality,
    required this.street,
    this.zipCode,
    required this.label,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString() ?? '',
      province: json['province']?.toString() ?? json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? json['city']?.toString() ?? '',
      municipality: json['municipality']?.toString() ?? '',
      street: json['street']?.toString() ?? json['full_address']?.toString() ?? json['address']?.toString() ?? '',
      zipCode: json['zip_code']?.toString() ?? json['zipCode']?.toString(),
      label: json['label']?.toString() ?? '',
      isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'municipality': municipality,
      'street': street,
      if (zipCode != null && zipCode!.isNotEmpty) 'zip_code': zipCode,
      'label': label,
      'is_default': isDefault,
    };
  }

  String get displayText {
    final parts = [street, municipality, district, province, zipCode]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
