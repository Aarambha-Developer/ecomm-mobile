class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
