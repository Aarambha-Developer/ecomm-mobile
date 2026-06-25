class HeroSection {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? buttonLabel;
  final String? buttonLink;
  final List<HeroSlide> slides;

  const HeroSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.buttonLabel,
    this.buttonLink,
    this.slides = const [],
  });

  factory HeroSection.fromJson(Map<String, dynamic> json) {
    List<HeroSlide> parsedSlides = [];
    if (json['slides'] is List) {
      parsedSlides = (json['slides'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => HeroSlide.fromJson(e))
          .toList();
    }
    return HeroSection(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      buttonLabel: json['button_label'] as String?,
      buttonLink: json['button_link'] as String?,
      slides: parsedSlides,
    );
  }
}

class HeroSlide {
  final int id;
  final String? image;
  final String? altText;
  final int displayOrder;
  final bool isActive;

  const HeroSlide({
    required this.id,
    this.image,
    this.altText,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: json['id'] as int? ?? 0,
      image: json['image'] as String?,
      altText: json['alt_text'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class Offer {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final String? link;
  final String? buttonText;
  final String? category;
  final bool isActive;
  final String? discountType;
  final double? discountValue;
  final double? minCartValue;

  const Offer({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.link,
    this.buttonText,
    this.category,
    this.isActive = true,
    this.discountType,
    this.discountValue,
    this.minCartValue,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return Offer(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      link: json['link'] as String?,
      buttonText: json['button_text'] as String? ?? json['discount_text'] as String?,
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      discountType: json['discount_type'] as String?,
      discountValue: parseDouble(json['discount_value']),
      minCartValue: parseDouble(json['min_cart_value']),
    );
  }
}
