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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      teamMembers: List<String>.from(json['team_members']),
      progress: json['progress'],
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
    );
  }
}
