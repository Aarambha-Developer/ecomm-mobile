class PaymentMethod {
  final String id;
  final String title;
  final String type;
  final String? qrImage;
  final String? accountName;
  final String? accountNumber;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.title,
    required this.type,
    this.qrImage,
    this.accountName,
    this.accountNumber,
    this.isActive = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      qrImage: json['qr_image'] as String?,
      accountName: json['account_name'] as String?,
      accountNumber: json['account_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get isQr => type == 'qr';
  bool get isCod => type == 'cod';
  bool get isGateway =>
      type == 'gateway_esewa' || type == 'gateway_khalti';
}
