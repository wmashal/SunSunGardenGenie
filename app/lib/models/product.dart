class Product {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? dimensions;
  final String? color;
  final String? thumbnailUrl;
  final List<String>? aiTags;

  Product({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.dimensions,
    this.color,
    this.thumbnailUrl,
    this.aiTags,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown',
      category: json['category'],
      description: json['description'],
      dimensions: json['dimensions'],
      color: json['color'],
      thumbnailUrl: json['thumbnail_url'],
      aiTags: json['ai_tags'] != null ? List<String>.from(json['ai_tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'dimensions': dimensions,
      'color': color,
      'thumbnail_url': thumbnailUrl,
    };
  }
}
