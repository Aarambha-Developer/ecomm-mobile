class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String? productSlug;
  final String? productImage;
  final double unitPrice;
  final double subtotal;
  final int quantity;
  final int stockQuantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.productImage,
    required this.unitPrice,
    required this.subtotal,
    required this.quantity,
    this.stockQuantity = 0,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    Map<String, dynamic>? product;
    if (json['product'] is Map) {
      product = Map<String, dynamic>.from(json['product']);
    }

    Map<String, dynamic>? primaryImage;
    if (product?['primary_image'] is Map) {
      primaryImage = Map<String, dynamic>.from(product!['primary_image']);
    }

    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: product?['id']?.toString() ?? '',
      productName: product?['name'] as String? ?? '',
      productSlug: product?['slug'] as String?,
      productImage: primaryImage?['image'] as String?,
      unitPrice: parsePrice(json['unit_price']),
      subtotal: parsePrice(json['subtotal']),
      quantity: json['quantity'] as int? ?? 1,
      stockQuantity: product?['stock_quantity'] as int? ?? 0,
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
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItem.fromJson(e))
          .toList();
    }

    return Cart(
      id: json['id']?.toString() ?? '',
      items: parsedItems,
      totalItems: json['total_items'] as int? ?? 0,
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
