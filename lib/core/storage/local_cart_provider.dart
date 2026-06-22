import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  LocalCartNotifier() : super(const LocalCart());

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
  }

  void removeItem(String productId) {
    state = LocalCart(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
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
  }

  void clear() {
    state = const LocalCart();
  }
}

final localCartProvider =
    StateNotifierProvider<LocalCartNotifier, LocalCart>((ref) {
  return LocalCartNotifier();
});
