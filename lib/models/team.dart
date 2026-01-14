class Team {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final String? ownerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int membersCount;
  final List<TeamMember>? members;

  Team({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.ownerName,
    this.createdAt,
    this.updatedAt,
    this.membersCount = 0,
    this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      membersCount: json['members_count'] ?? 0,
      members: json['members'] != null
          ? (json['members'] as List).map((m) => TeamMember.fromJson(m)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'members_count': membersCount,
      'members': members?.map((m) => m.toJson()).toList(),
    };
  }
}

class TeamMember {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? joinedAt;
  final String? avatarUrl;

  TeamMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.joinedAt,
    this.avatarUrl,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'],
      fullName: json['full_name'] ?? json['email']?.split('@')[0] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}
