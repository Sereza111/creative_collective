import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../models/project.dart';
import '../models/finance.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Tasks
  static Future<List<Task>> getTasks(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((task) => Task.fromJson(task)).toList();
    } else {
      throw Exception('Ошибка загрузки задач');
    }
  }

  static Future<Task> createTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Ошибка создания задачи');
    }
  }

  // Projects
  static Future<List<Project>> getProjects() async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((project) => Project.fromJson(project)).toList();
    } else {
      throw Exception('Ошибка загрузки проектов');
    }
  }

  // Finance
  static Future<Finance> getFinance(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/finance/$userId'),
    );

    if (response.statusCode == 200) {
      return Finance.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Ошибка загрузки финансов');
    }
  }
}
