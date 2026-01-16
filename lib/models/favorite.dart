class Favorite {
  final int id;
  final int userId;
  final String favoritedType; // 'order' or 'freelancer'
  final int favoritedId;
  final DateTime createdAt;
  final String? title;
  final String? description;
  final double? budget;
  final String? status;
  final double? rating;
  final int? reviewsCount;

  Favorite({
    required this.id,
    required this.userId,
    required this.favoritedType,
    required this.favoritedId,
    required this.createdAt,
    this.title,
    this.description,
    this.budget,
    this.status,
    this.rating,
    this.reviewsCount,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      favoritedType: json['favorited_type'] ?? '',
      favoritedId: json['favorited_id'] is int ? json['favorited_id'] : int.tryParse(json['favorited_id'].toString()) ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      title: json['title'],
      description: json['description'],
      budget: json['budget'] != null 
          ? (json['budget'] is String ? double.tryParse(json['budget']) : (json['budget'] as num?)?.toDouble())
          : null,
      status: json['status'],
      rating: json['rating'] != null 
          ? (json['rating'] is String ? double.tryParse(json['rating']) : (json['rating'] as num?)?.toDouble())
          : null,
      reviewsCount: json['reviews_count'] is int 
          ? json['reviews_count'] 
          : (json['reviews_count'] != null ? int.tryParse(json['reviews_count'].toString()) : null),
    );
  }

  bool get isOrder => favoritedType == 'order';
  bool get isFreelancer => favoritedType == 'freelancer';
}

