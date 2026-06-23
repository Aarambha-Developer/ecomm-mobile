class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String? shippingAddress;
  final String? notes;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? coupon;
  final double? discountAmount;
  final int totalItems;
  final double totalPrice;
  final double subtotalPrice;
  final Map<String, dynamic>? paymentProof;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.shippingAddress,
    this.notes,
    this.paymentMethod,
    this.paymentStatus,
    this.coupon,
    this.discountAmount,
    this.totalItems = 0,
    this.totalPrice = 0,
    this.subtotalPrice = 0,
    this.paymentProof,
    this.updatedAt,
    this.items = const [],
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    List<OrderItem> items = [];
    if (itemsRaw is List) {
      items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderItem.fromJson(e))
          .toList();
    }
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method_title'] as String?,
      paymentStatus: json['payment_status'] as String?,
      coupon: json['coupon'] as String? ?? json['coupon_code'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      subtotalPrice: (json['subtotal_price'] as num?)?.toDouble() ?? 0,
      paymentProof: json['payment_proof'] as Map<String, dynamic>?,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      items: items,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isRefunded => status == 'refunded';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
      productImage: json['product_image'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
