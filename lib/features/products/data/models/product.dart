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
  final String? fullDescription;
  final DateTime? createdAt;
  final List<ProductReview> reviews;

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
    this.fullDescription,
    this.createdAt,
    this.reviews = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        for (final key in ['name', 'title', 'value', 'text', 'label']) {
          final nested = val[key];
          if (nested is String && nested.isNotEmpty) return nested;
        }
      }
      final raw = val.toString();
      return raw.isEmpty ? null : raw;
    }

    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    Map<String, dynamic>? category;
    if (json['category'] is Map) {
      category = Map<String, dynamic>.from(json['category'] as Map);
    }

    Map<String, dynamic>? brand;
    if (json['brand'] is Map) {
      brand = Map<String, dynamic>.from(json['brand'] as Map);
    }

    Map<String, dynamic>? primaryImageObj;
    if (json['primary_image'] is Map) {
      primaryImageObj = Map<String, dynamic>.from(json['primary_image'] as Map);
    }

    List<ProductImage> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((e) => e is Map ? ProductImage.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<ProductImage>()
          .toList();
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: parseString(json['name']) ?? '',
      slug: parseString(json['slug']) ?? '',
      categoryId: category?['id']?.toString(),
      categoryName: parseString(category?['name']),
      categorySlug: parseString(category?['slug']),
      brandId: brand?['id']?.toString(),
      brandName: parseString(brand?['title']),
      brandSlug: parseString(brand?['slug']),
      description: parseString(json['description']),
      price: parsePrice(json['price']),
      discountPercentage: parsePrice(json['discount_percentage']),
      discountedPrice: parsePrice(json['discounted_price']),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      rating: parsePrice(json['rating']),
      primaryImage: parseString(primaryImageObj?['image']),
      images: parsedImages,
      fullDescription: parseString(json['full_description']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => e is Map ? ProductReview.fromJson(Map<String, dynamic>.from(e)) : null)
              .whereType<ProductReview>()
              .toList() ??
          [],
    );
  }

  bool get hasDiscount => discountPercentage > 0;
  bool get inStock => stockQuantity > 0;
}

class ProductReview {
  final String id;
  final String? user;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductReview({
    required this.id,
    this.user,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) {
        final display = val['full_name'] ?? val['name'] ?? val['email'];
        if (display is String && display.isNotEmpty) return display;
      }
      return val.toString();
    }

    return ProductReview(
      id: json['id']?.toString() ?? '',
      user: parseString(json['user']),
      rating: json['rating'] as int? ?? 0,
      comment: parseString(json['comment']) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
