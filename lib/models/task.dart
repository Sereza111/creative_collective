class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String assignedTo;
  final DateTime dueDate;
  final int priority; // 1-5
  final String projectId;
  final DateTime createdAt;
  final String? assignedFullName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.projectId,
    required this.createdAt,
    this.assignedFullName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Без названия',
      description: json['description'] ?? '',
      status: json['status'] ?? 'todo',
      assignedTo: json['assigned_to'] ?? '',
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) 
          : DateTime.now().add(const Duration(days: 7)),
      priority: _parseInt(json['priority']),
      projectId: json['project_id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      assignedFullName: json['assigned_full_name'],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 3;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 3;
    return 3;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'assigned_to': assignedTo,
      'due_date': dueDate.toIso8601String(),
      'priority': priority,
      'project_id': projectId,
    };
  }
}
