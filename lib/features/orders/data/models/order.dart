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
  final double? deliveryCharge;
  final int totalItems;
  final double totalPrice;
  final double subtotalPrice;
  final Map<String, dynamic>? paymentProof;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  final DateTime createdAt;

  final String? shippingFullName;
  final String? shippingPhone;
  final String? shippingEmail;
  final String? shippingProvince;
  final String? shippingDistrict;
  final String? shippingMunicipality;
  final String? shippingStreet;
  final String? shippingZipCode;

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
    this.deliveryCharge,
    this.totalItems = 0,
    this.totalPrice = 0,
    this.subtotalPrice = 0,
    this.paymentProof,
    this.updatedAt,
    this.items = const [],
    required this.createdAt,
    this.shippingFullName,
    this.shippingPhone,
    this.shippingEmail,
    this.shippingProvince,
    this.shippingDistrict,
    this.shippingMunicipality,
    this.shippingStreet,
    this.shippingZipCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        for (final key in [
          'full_address',
          'address',
          'title',
          'name',
          'value',
          'code'
        ]) {
          final nested = val[key];
          if (nested is String && nested.isNotEmpty) return nested;
        }
      }
      final raw = val.toString();
      return raw.isEmpty ? null : raw;
    }

    String? parseAddress(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        final ordered = [
          val['full_address'],
          val['address'],
          val['city'],
          val['state'],
          val['zip_code'] ?? val['zip'],
          val['country'],
        ];
        final parts = ordered
            .map((e) => e?.toString().trim())
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
      return val.toString();
    }

    final itemsRaw = json['items'];
    List<OrderItem> items = [];
    if (itemsRaw is List) {
      items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderItem.fromJson(e))
          .toList();
    }
    double parseDouble(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['id']?.toString() ?? '',
      status: parseString(json['status']) ?? 'pending',
      totalAmount: parseDouble(json['total_amount'] ?? json['total_price']),
      shippingAddress: parseAddress(json['shipping_address']),
      notes: parseString(json['notes']),
      paymentMethod: parseString(json['payment_method_title'] ?? json['payment_method']),
      paymentStatus: parseString(json['payment_status']),
      coupon: parseString(json['coupon'] ?? json['coupon_code']),
      discountAmount: json['discount_amount'] != null ? parseDouble(json['discount_amount']) : null,
      totalItems: json['total_items'] is num ? (json['total_items'] as num).toInt() : (int.tryParse(json['total_items']?.toString() ?? '') ?? 0),
      totalPrice: parseDouble(json['total_price']),
      subtotalPrice: parseDouble(json['subtotal_price']),
      paymentProof: json['payment_proof'] is Map
          ? Map<String, dynamic>.from(json['payment_proof'] as Map)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      items: items,
      createdAt: _parseDate(json['created_at']),
      deliveryCharge: json['delivery_charge'] != null ? parseDouble(json['delivery_charge']) : null,
      shippingFullName: parseString(json['shipping_full_name']),
      shippingPhone: parseString(json['shipping_phone']),
      shippingEmail: parseString(json['shipping_email']),
      shippingProvince: parseString(json['shipping_province']),
      shippingDistrict: parseString(json['shipping_district']),
      shippingMunicipality: parseString(json['shipping_municipality']),
      shippingStreet: parseString(json['shipping_street']),
      shippingZipCode: parseString(json['shipping_zip_code']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  String? get formattedShippingAddress {
    if (shippingStreet != null ||
        shippingMunicipality != null ||
        shippingDistrict != null ||
        shippingProvince != null) {
      final parts = [
        shippingStreet,
        shippingMunicipality,
        shippingDistrict,
        shippingProvince,
        shippingZipCode,
      ].where((e) => e != null && e.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return shippingAddress;
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
    double parseDouble(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        final nested = val['name'] ?? val['title'] ?? val['image'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
      return val.toString();
    }

    String prodId = '';
    String prodName = '';
    String? prodImage;

    final productRaw = json['product'];
    if (productRaw is Map) {
      final productMap = Map<String, dynamic>.from(productRaw);
      prodId = productMap['id']?.toString() ?? '';
      prodName = parseString(productMap['name']) ?? '';
      
      final img = productMap['primary_image'];
      if (img is Map) {
        prodImage = parseString(img['image']);
      } else {
        prodImage = parseString(img);
      }
    } else {
      prodId = json['product_id']?.toString() ?? json['product']?.toString() ?? '';
      prodName = parseString(json['product_name'] ?? json['name']) ?? '';
      prodImage = parseString(json['product_image']);
    }

    final priceRaw = json['price_at_purchase'] ?? json['price'];
    final quantityRaw = json['quantity'];
    final qty = quantityRaw is num ? quantityRaw.toInt() : (int.tryParse(quantityRaw?.toString() ?? '') ?? 1);

    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: prodId,
      productName: prodName,
      productImage: prodImage,
      quantity: qty,
      price: parseDouble(priceRaw),
    );
  }
}
