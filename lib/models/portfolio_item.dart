class PortfolioItem {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? projectUrl;
  final String? category;
  final List<String> skills;
  final DateTime? completedAt;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortfolioItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.projectUrl,
    this.category,
    required this.skills,
    this.completedAt,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    List<String> skillsList = [];
    if (json['skills'] != null) {
      if (json['skills'] is String) {
        // Если skills - строка JSON, парсим её
        try {
          final decoded = json['skills'];
          skillsList = List<String>.from(decoded is List ? decoded : []);
        } catch (e) {
          skillsList = [];
        }
      } else if (json['skills'] is List) {
        skillsList = List<String>.from(json['skills']);
      }
    }

    return PortfolioItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      projectUrl: json['project_url'],
      category: json['category'],
      skills: skillsList,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      displayOrder: json['display_order'] is int ? json['display_order'] : int.parse(json['display_order'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'project_url': projectUrl,
      'category': category,
      'skills': skills,
      'completed_at': completedAt?.toIso8601String(),
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

