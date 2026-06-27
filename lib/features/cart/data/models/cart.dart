class AppliedOffer {
  final String title;
  final String discountType;
  final double discountValue;

  const AppliedOffer({
    required this.title,
    required this.discountType,
    required this.discountValue,
  });

  factory AppliedOffer.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    return AppliedOffer(
      title: json['title']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? '',
      discountValue: parsePrice(json['discount_value']),
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String? productSlug;
  final String? productImage;
  final double unitPrice;
  final double subtotal;
  final double basePrice;
  final double baseSubtotal;
  final double totalSavings;
  final int quantity;
  final int stockQuantity;
  final List<AppliedOffer> appliedOffers;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.productImage,
    required this.unitPrice,
    required this.subtotal,
    this.basePrice = 0.0,
    this.baseSubtotal = 0.0,
    this.totalSavings = 0.0,
    required this.quantity,
    this.stockQuantity = 0,
    this.appliedOffers = const [],
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    Map<String, dynamic>? product;
    if (json['product'] is Map) {
      product = Map<String, dynamic>.from(json['product'] as Map);
    }

    String? prodImage;
    if (product != null) {
      final img = product['primary_image'];
      if (img is Map) {
        prodImage = img['image']?.toString();
      } else {
        prodImage = img?.toString();
      }
    }

    List<AppliedOffer> parsedOffers = [];
    if (json['applied_offers'] is List) {
      parsedOffers = (json['applied_offers'] as List)
          .map((e) => e is Map ? AppliedOffer.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<AppliedOffer>()
          .toList();
    }

    final double uPrice = parsePrice(json['unit_price']);
    final double qty = (json['quantity'] as num? ?? 1).toDouble();
    final double bPrice = json['base_price'] != null ? parsePrice(json['base_price']) : parsePrice(product?['price'] ?? uPrice);

    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: product?['id']?.toString() ?? '',
      productName: product?['name'] as String? ?? '',
      productSlug: product?['slug'] as String?,
      productImage: prodImage,
      unitPrice: uPrice,
      subtotal: parsePrice(json['subtotal']),
      basePrice: bPrice,
      baseSubtotal: json['base_subtotal'] != null ? parsePrice(json['base_subtotal']) : (bPrice * qty),
      totalSavings: json['total_savings'] != null ? parsePrice(json['total_savings']) : 0.0,
      quantity: json['quantity'] as int? ?? 1,
      stockQuantity: product?['stock_quantity'] as int? ?? 0,
      appliedOffers: parsedOffers,
    );
  }
}

class Cart {
  final String id;
  final List<CartItem> items;
  final int totalItems;
  final double totalAmount;

  const Cart({
    required this.id,
    this.items = const [],
    this.totalItems = 0,
    this.totalAmount = 0,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    List<CartItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final totalItemsRaw = json['total_items'];
    final totalItems = totalItemsRaw is num ? totalItemsRaw.toInt() : (int.tryParse(totalItemsRaw?.toString() ?? '') ?? 0);

    return Cart(
      id: json['id']?.toString() ?? '',
      items: parsedItems,
      totalItems: totalItems,
      totalAmount: (() {
        final v = json['total_amount'];
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0;
      })(),
    );
  }

  bool get isEmpty => items.isEmpty;
}
