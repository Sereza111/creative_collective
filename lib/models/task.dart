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
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      assignedTo: json['assigned_to'],
      dueDate: DateTime.parse(json['due_date']),
      priority: json['priority'],
      projectId: json['project_id'],
    );
  }
}
