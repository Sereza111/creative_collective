class Review {
  final int id;
  final int orderId;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Дополнительные поля из JOIN
  final String? orderTitle;
  final String? reviewerName;
  final String? reviewerEmail;
  final String? reviewerAvatar;
  final String? reviewerRole;
  final String? revieweeName;
  final String? revieweeEmail;

  Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.orderTitle,
    this.reviewerName,
    this.reviewerEmail,
    this.reviewerAvatar,
    this.reviewerRole,
    this.revieweeName,
    this.revieweeEmail,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      orderId: json['order_id'] is int ? json['order_id'] : int.parse(json['order_id'].toString()),
      reviewerId: json['reviewer_id'] is int ? json['reviewer_id'] : int.parse(json['reviewer_id'].toString()),
      revieweeId: json['reviewee_id'] is int ? json['reviewee_id'] : int.parse(json['reviewee_id'].toString()),
      rating: json['rating'] is int ? json['rating'] : int.parse(json['rating'].toString()),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      orderTitle: json['order_title'],
      reviewerName: json['reviewer_name'],
      reviewerEmail: json['reviewer_email'],
      reviewerAvatar: json['reviewer_avatar'],
      reviewerRole: json['reviewer_role'],
      revieweeName: json['reviewee_name'],
      revieweeEmail: json['reviewee_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserRating {
  final double? averageRating;
  final int reviewsCount;
  final Map<int, int> ratingDistribution;

  UserRating({
    this.averageRating,
    required this.reviewsCount,
    required this.ratingDistribution,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{};
    if (json['rating_distribution'] != null) {
      final distMap = json['rating_distribution'] as Map<String, dynamic>;
      distMap.forEach((key, value) {
        distribution[int.parse(key)] = value is int ? value : int.parse(value.toString());
      });
    }

    return UserRating(
      averageRating: json['average_rating'] != null 
          ? (json['average_rating'] is double 
              ? json['average_rating'] 
              : double.parse(json['average_rating'].toString()))
          : null,
      reviewsCount: json['reviews_count'] is int 
          ? json['reviews_count'] 
          : int.parse(json['reviews_count'].toString()),
      ratingDistribution: distribution,
    );
  }
}

