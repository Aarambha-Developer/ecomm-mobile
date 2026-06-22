import 'package:aarambha_app/features/products/data/models/product.dart';

class WishlistItem {
  final String id;
  final Product product;

  const WishlistItem({
    required this.id,
    required this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? productData;
    if (json['product'] is Map) {
      productData = Map<String, dynamic>.from(json['product'] as Map);
    }
    return WishlistItem(
      id: json['id']?.toString() ?? '',
      product: productData != null
          ? Product.fromJson(productData)
          : Product(id: '', name: '', slug: ''),
    );
  }
}

class Wishlist {
  final String id;
  final List<WishlistItem> items;

  const Wishlist({
    required this.id,
    this.items = const [],
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    List<WishlistItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => WishlistItem.fromJson(e))
          .toList();
    }
    return Wishlist(
      id: json['id']?.toString() ?? '',
      items: parsedItems,
    );
  }

  bool get isEmpty => items.isEmpty;
  int get productCount => items.length;
}
