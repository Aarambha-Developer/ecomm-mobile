class DeliveryArea {
  final String id;
  final String province;
  final String district;
  final String municipality;
  final double deliveryCharge;
  final bool isAvailable;
  final String estimatedDays;

  const DeliveryArea({
    required this.id,
    required this.province,
    required this.district,
    required this.municipality,
    required this.deliveryCharge,
    required this.isAvailable,
    required this.estimatedDays,
  });

  factory DeliveryArea.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return DeliveryArea(
      id: json['id']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      municipality: json['municipality']?.toString() ?? '',
      deliveryCharge: parseDouble(json['delivery_charge']),
      isAvailable: json['is_available'] as bool? ?? true,
      estimatedDays: json['estimated_days']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'province': province,
      'district': district,
      'municipality': municipality,
      'delivery_charge': deliveryCharge.toStringAsFixed(2),
      'is_available': isAvailable,
      'estimated_days': estimatedDays,
    };
  }
}
