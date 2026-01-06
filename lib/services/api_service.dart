import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../models/project.dart';
import '../models/finance.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://85.198.103.11:8080/api/v1'; // Используем порт 8080
  
  // Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // =============================================
  // AUTH
  // =============================================
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Save tokens
        await SecureStorageService.saveTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
        );
        // Save user ID
        if (data['data']['user'] != null) {
          await SecureStorageService.saveUserId(data['data']['user']['id']);
        }
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Ошибка входа');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка входа');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Save tokens
        await SecureStorageService.saveTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
        );
        // Save user ID
        if (data['data']['user'] != null) {
          await SecureStorageService.saveUserId(data['data']['user']['id']);
        }
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Ошибка регистрации');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка регистрации');
    }
  }

  static Future<void> logout() async {
    await SecureStorageService.clearAll();
  }

  static Future<User> getCurrentUser() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return User.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка получения данных пользователя');
    } else {
      throw Exception('Ошибка получения данных пользователя');
    }
  }

  // =============================================
  // TASKS
  // =============================================

  static Future<List<Task>> getTasks({String? projectId, String? status}) async {
    final queryParams = <String, String>{};
    if (projectId != null) queryParams['project_id'] = projectId;
    if (status != null) queryParams['status'] = status;
    
    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Check if data['data'] is a List or an object with pagination
        final tasksData = data['data'];
        if (tasksData is List) {
          return tasksData.map((task) => Task.fromJson(task)).toList();
        } else if (tasksData is Map && tasksData['data'] is List) {
          final List<dynamic> tasks = tasksData['data'];
          return tasks.map((task) => Task.fromJson(task)).toList();
        }
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки задач: ${response.statusCode}');
    }
  }

  static Future<Task> createTask(Map<String, dynamic> taskData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: headers,
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Task.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка создания задачи');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания задачи');
    }
  }

  static Future<Task> updateTask(String taskId, Map<String, dynamic> taskData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: headers,
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Task.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка обновления задачи');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления задачи');
    }
  }

  static Future<void> deleteTask(String taskId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления задачи');
    }
  }

  // =============================================
  // PROJECTS
  // =============================================

  static Future<List<Project>> getProjects({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    
    final uri = Uri.parse('$baseUrl/projects').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Check if data['data'] is a List or an object with pagination
        final projectsData = data['data'];
        if (projectsData is List) {
          return projectsData.map((project) => Project.fromJson(project)).toList();
        } else if (projectsData is Map && projectsData['data'] is List) {
          final List<dynamic> projects = projectsData['data'];
          return projects.map((project) => Project.fromJson(project)).toList();
        }
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки проектов: ${response.statusCode}');
    }
  }

  static Future<Project> createProject(Map<String, dynamic> projectData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: headers,
      body: jsonEncode(projectData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Project.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка создания проекта');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания проекта');
    }
  }

  static Future<void> deleteProject(String projectId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления проекта');
    }
  }

  // =============================================
  // FINANCE
  // =============================================

  static Future<Finance> getFinance(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/finance/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Finance.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка загрузки финансов');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка загрузки финансов');
    }
  }

  static Future<List<dynamic>> getTransactions(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/finance/$userId/transactions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки транзакций');
    }
  }

  static Future<dynamic> createTransaction(String userId, Map<String, dynamic> transactionData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/finance/$userId/transactions'),
      headers: headers,
      body: jsonEncode(transactionData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Ошибка создания транзакции');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания транзакции');
    }
  }

  // =============================================
  // TEAMS
  // =============================================
  
  static Future<List<dynamic>> getTeams() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки команд');
    }
  }
}
