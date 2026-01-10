class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String assignedTo;
  final DateTime dueDate;
  final int priority; // 1-5
  final String projectId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.projectId,
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
      priority: json['priority'] ?? 3,
      projectId: json['project_id'] ?? '',
    );
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
