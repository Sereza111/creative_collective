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
      progress: _parseInt(json['progress']),
      budget: _parseDouble(json['budget']),
      spent: _parseDouble(json['spent']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
