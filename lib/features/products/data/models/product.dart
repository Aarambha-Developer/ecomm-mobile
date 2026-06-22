class ProductImage {
  final String id;
  final String image;
  final String? altText;
  final bool isPrimary;
  final int order;

  const ProductImage({
    required this.id,
    required this.image,
    this.altText,
    this.isPrimary = false,
    this.order = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      image: json['image'] as String? ?? '',
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String slug;
  final String? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? brandId;
  final String? brandName;
  final String? brandSlug;
  final String? description;
  final double price;
  final double discountPercentage;
  final double discountedPrice;
  final int stockQuantity;
  final bool isActive;
  final double rating;
  final String? primaryImage;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.brandId,
    this.brandName,
    this.brandSlug,
    this.description,
    this.price = 0,
    this.discountPercentage = 0,
    this.discountedPrice = 0,
    this.stockQuantity = 0,
    this.isActive = true,
    this.rating = 0,
    this.primaryImage,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    Map<String, dynamic>? category;
    if (json['category'] is Map) {
      category = Map<String, dynamic>.from(json['category']);
    }

    Map<String, dynamic>? brand;
    if (json['brand'] is Map) {
      brand = Map<String, dynamic>.from(json['brand']);
    }

    Map<String, dynamic>? primaryImageObj;
    if (json['primary_image'] is Map) {
      primaryImageObj = Map<String, dynamic>.from(json['primary_image']);
    }

    List<ProductImage> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductImage.fromJson(e))
          .toList();
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryId: category?['id']?.toString(),
      categoryName: category?['name'] as String?,
      categorySlug: category?['slug'] as String?,
      brandId: brand?['id']?.toString(),
      brandName: brand?['title'] as String?,
      brandSlug: brand?['slug'] as String?,
      description: json['description'] as String?,
      price: parsePrice(json['price']),
      discountPercentage: parsePrice(json['discount_percentage']),
      discountedPrice: parsePrice(json['discounted_price']),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      rating: parsePrice(json['rating']),
      primaryImage: primaryImageObj?['image'] as String?,
      images: parsedImages,
    );
  }

  bool get hasDiscount => discountPercentage > 0;
  bool get inStock => stockQuantity > 0;
}
