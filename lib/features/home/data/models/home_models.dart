class HeroSlide {
  final String id;
  final String title;
  final String? subtitle;
  final String? image;
  final String? link;
  final String? linkType;
  final int sortOrder;
  final bool isActive;

  const HeroSlide({
    required this.id,
    required this.title,
    this.subtitle,
    this.image,
    this.link,
    this.linkType,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      image: json['image'] as String? ?? json['image_url'] as String?,
      link: json['link'] as String?,
      linkType: json['link_type'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
  final String? discountText;
  final bool isActive;

  const Offer({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.link,
    this.discountText,
    this.isActive = true,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String? ?? json['image_url'] as String?,
      link: json['link'] as String?,
      discountText: json['discount_text'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
