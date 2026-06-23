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
    final slug = json['slug'] as String? ?? '';
    return Brand(
      id: json['id']?.toString() ?? slug,
      title: json['title'] as String? ?? '',
      slug: slug,
      image: json['image'] as String?,
    );
  }
}
