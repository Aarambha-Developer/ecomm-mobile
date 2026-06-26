import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage.dart';

class LocalCartItem {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;

  const LocalCartItem({
    required this.productId,
    required this.productName,
    this.productImage,
    this.price = 0,
    this.quantity = 1,
  });

  LocalCartItem copyWith({int? quantity}) {
    return LocalCartItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'price': price,
      'quantity': quantity,
    };
  }

  factory LocalCartItem.fromJson(Map<String, dynamic> json) {
    return LocalCartItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class LocalCart {
  final List<LocalCartItem> items;

  const LocalCart({this.items = const []});

  int get itemCount => items.fold<int>(0, (sum, i) => sum + i.quantity);
  double get totalAmount =>
      items.fold<double>(0, (sum, i) => sum + (i.price * i.quantity));
  bool get isEmpty => items.isEmpty;
}

class LocalCartNotifier extends StateNotifier<LocalCart> {
  final SecureStorage _storage;
  static const _localCartStorageKey = 'local_cart_items';

  LocalCartNotifier(this._storage) : super(const LocalCart()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final jsonStr = await _storage.read(_localCartStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          final items = decoded
              .map((item) => LocalCartItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          state = LocalCart(items: items);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final serialized = jsonEncode(state.items.map((e) => e.toJson()).toList());
      await _storage.write(_localCartStorageKey, serialized);
    } catch (_) {}
  }

  void addItem({
    required String productId,
    required String productName,
    String? productImage,
    double price = 0,
    int quantity = 1,
  }) {
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == productId,
    );
    if (existingIndex >= 0) {
      final updated = state.items.toList();
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + quantity,
      );
      state = LocalCart(items: updated);
    } else {
      state = LocalCart(
        items: [
          ...state.items,
          LocalCartItem(
            productId: productId,
            productName: productName,
            productImage: productImage,
            price: price,
            quantity: quantity,
          ),
        ],
      );
    }
    _saveToStorage();
  }

  void removeItem(String productId) {
    state = LocalCart(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
    _saveToStorage();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = LocalCart(
      items: state.items
          .map((i) =>
              i.productId == productId ? i.copyWith(quantity: quantity) : i)
          .toList(),
    );
    _saveToStorage();
  }

  void clear() {
    state = const LocalCart();
    _saveToStorage();
  }
}

final localCartProvider =
    StateNotifierProvider<LocalCartNotifier, LocalCart>((ref) {
  final storage = ref.read(secureStorageProvider);
  return LocalCartNotifier(storage);
});
