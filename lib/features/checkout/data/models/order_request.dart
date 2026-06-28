class OrderRequest {
  final String shippingFullName;
  final String shippingPhone;
  final String shippingEmail;
  final String shippingProvince;
  final String shippingDistrict;
  final String shippingMunicipality;
  final String shippingStreet;
  final String shippingZipCode;
  final String notes;

  const OrderRequest({
    required this.shippingFullName,
    required this.shippingPhone,
    required this.shippingEmail,
    required this.shippingProvince,
    required this.shippingDistrict,
    required this.shippingMunicipality,
    required this.shippingStreet,
    this.shippingZipCode = '',
    this.notes = '',
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    return OrderRequest(
      shippingFullName: json['shipping_full_name']?.toString() ?? '',
      shippingPhone: json['shipping_phone']?.toString() ?? '',
      shippingEmail: json['shipping_email']?.toString() ?? '',
      shippingProvince: json['shipping_province']?.toString() ?? '',
      shippingDistrict: json['shipping_district']?.toString() ?? '',
      shippingMunicipality: json['shipping_municipality']?.toString() ?? '',
      shippingStreet: json['shipping_street']?.toString() ?? '',
      shippingZipCode: json['shipping_zip_code']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipping_full_name': shippingFullName,
      'shipping_phone': shippingPhone,
      'shipping_email': shippingEmail,
      'shipping_province': shippingProvince,
      'shipping_district': shippingDistrict,
      'shipping_municipality': shippingMunicipality,
      'shipping_street': shippingStreet,
      'shipping_zip_code': shippingZipCode,
      'notes': notes,
    };
  }
}
