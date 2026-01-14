import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../models/project.dart';
import '../models/finance.dart';
import '../models/user.dart';
import '../models/team.dart';
import '../models/order.dart';
import '../models/order_application.dart';
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
          final userId = data['data']['user']['id'];
          await SecureStorageService.saveUserId(userId.toString());
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
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
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
          final userId = data['data']['user']['id'];
          await SecureStorageService.saveUserId(userId.toString());
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

  static Future<User> updateUserProfile(Map<String, dynamic> profileData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
      body: jsonEncode(profileData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return User.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка обновления профиля');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления профиля');
    }
  }

  // =============================================
  // TASKS
  // =============================================

  static Future<List<Task>> getTasks({String? projectId, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (projectId != null) queryParams['project_id'] = projectId;
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Превышено время ожидания ответа от сервера'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          print('API returned null data for tasks');
          return [];
        }
        
        if (data['success'] == true) {
          final tasksData = data['data'];
          
          if (tasksData == null) {
            return [];
          }
          
          if (tasksData is List) {
            return tasksData.map((task) => Task.fromJson(task)).toList();
          } else if (tasksData is Map && tasksData['data'] != null) {
            final List<dynamic> tasks = tasksData['data'] ?? [];
            return tasks.map((task) => Task.fromJson(task)).toList();
          }
        }
        return [];
      } else {
        throw Exception('Ошибка загрузки задач: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTasks: $e');
      rethrow;
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

  static Future<Task> updateTask(int taskId, Map<String, dynamic> taskData) async {
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

  static Future<void> deleteTask(int taskId) async {
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
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/projects').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Превышено время ожидания ответа от сервера'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          print('API returned null data');
          return [];
        }
        
        if (data['success'] == true) {
          final projectsData = data['data'];
          
          if (projectsData == null) {
            return [];
          }
          
          if (projectsData is List) {
            return projectsData.map((project) => Project.fromJson(project)).toList();
          } else if (projectsData is Map && projectsData['data'] != null) {
            final List<dynamic> projects = projectsData['data'] ?? [];
            return projects.map((project) => Project.fromJson(project)).toList();
          }
        }
        return [];
      } else {
        throw Exception('Ошибка загрузки проектов: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProjects: $e');
      rethrow;
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

  static Future<Project> updateProject(String projectId, Map<String, dynamic> projectData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: headers,
      body: jsonEncode(projectData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Project.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка обновления проекта');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления проекта');
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
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/finance/$userId/transactions'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Превышено время ожидания ответа от сервера'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          print('API returned null data for transactions');
          return [];
        }
        
        if (data['success'] == true) {
          final transactionsData = data['data'];
          if (transactionsData == null) {
            return [];
          }
          
          if (transactionsData is List) {
            return transactionsData;
          }
        }
        return [];
      } else {
        throw Exception('Ошибка загрузки транзакций: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTransactions: $e');
      rethrow;
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
  
  static Future<List<Team>> getTeams() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final teamsList = data['data'] is List ? data['data'] : [data['data']];
        return teamsList.map<Team>((json) => Team.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки команд');
    }
  }

  static Future<Team> createTeam(Map<String, dynamic> teamData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/teams'),
      headers: headers,
      body: jsonEncode(teamData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Team.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка создания команды');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания команды');
    }
  }

  static Future<Team> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: headers,
      body: jsonEncode(teamData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Team.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка обновления команды');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления команды');
    }
  }

  static Future<void> deleteTeam(int teamId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления команды');
    }
  }

  static Future<void> addTeamMember(int teamId, int userId, String role) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/teams/$teamId/members'),
      headers: headers,
      body: jsonEncode({'user_id': userId, 'role': role}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка добавления участника');
    }
  }

  static Future<void> removeTeamMember(int teamId, int userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/teams/$teamId/members/$userId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления участника');
    }
  }

  // =============================================
  // ORDERS (MARKETPLACE)
  // =============================================
  
  static Future<List<Order>> getOrders({String? status, String? category}) async {
    final headers = await _getHeaders();
    var url = '$baseUrl/orders?';
    if (status != null) url += 'status=$status&';
    if (category != null) url += 'category=$category&';
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final ordersList = data['data'] is List ? data['data'] : [data['data']];
        return ordersList.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки заказов');
    }
  }

  static Future<Order> getOrderById(int orderId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Заказ не найден');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка загрузки заказа');
    }
  }

  static Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: jsonEncode(orderData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка создания заказа');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания заказа');
    }
  }

  static Future<Order> updateOrder(int orderId, Map<String, dynamic> orderData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: headers,
      body: jsonEncode(orderData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Order.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка обновления заказа');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления заказа');
    }
  }

  static Future<void> deleteOrder(int orderId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления заказа');
    }
  }

  static Future<OrderApplication> applyToOrder(int orderId, Map<String, dynamic> applicationData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/apply'),
      headers: headers,
      body: jsonEncode(applicationData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return OrderApplication.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Ошибка отправки отклика');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка отправки отклика');
    }
  }

  static Future<List<OrderApplication>> getOrderApplications(int orderId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/applications'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final appsList = data['data'] is List ? data['data'] : [data['data']];
        return appsList.map<OrderApplication>((json) => OrderApplication.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки откликов');
    }
  }

  static Future<void> acceptApplication(int orderId, int applicationId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/applications/$applicationId/accept'),
      headers: headers,
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка принятия отклика');
    }
  }
}
