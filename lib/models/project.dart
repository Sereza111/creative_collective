class Project {
  final String id;
  final String name;
  final String description;
  final String status; // 'planning', 'active', 'on_hold', 'completed'
  final DateTime startDate;
  final DateTime endDate;
  final List<String> teamMembers;
  final int progress; // 0-100
  final double budget;
  final double spent;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.teamMembers,
    required this.progress,
    required this.budget,
    required this.spent,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Без названия',
      description: json['description'] ?? '',
      status: json['status'] ?? 'planning',
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : DateTime.now().add(const Duration(days: 30)),
      teamMembers: json['team_members'] != null 
          ? List<String>.from(json['team_members']) 
          : [],
      progress: json['progress'] ?? 0,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : 0.0,
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'team_members': teamMembers,
      'progress': progress,
      'budget': budget,
      'spent': spent,
    };
  }
}
