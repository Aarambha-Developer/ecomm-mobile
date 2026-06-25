class OrderRequest {
  final String shippingAddress;
  final String notes;

  const OrderRequest({
    required this.shippingAddress,
    this.notes = '',
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    return OrderRequest(
      shippingAddress: json['shipping_address']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipping_address': shippingAddress,
      'notes': notes,
    };
  }
}
