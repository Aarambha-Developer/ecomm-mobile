class Brand {
  final String id;
  final String title;
  final String slug;
  final String? image;

  const Brand({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      image: json['image'] as String?,
    );
  }
}
