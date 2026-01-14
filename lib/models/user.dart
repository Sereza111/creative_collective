class User {
  final int id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role; // team role: admin, manager, member
  final String userRole; // marketplace role: client, freelancer, admin
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    this.userRole = 'freelancer',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'member',
      userRole: json['user_role'] ?? 'freelancer',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'user_role': userRole,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? userRole,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      userRole: userRole ?? this.userRole,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

