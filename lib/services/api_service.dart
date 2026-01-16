import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import '../models/project.dart';
import '../models/finance.dart';
import '../models/user.dart';
import '../models/team.dart';
import '../models/order.dart';
import '../models/order_application.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/review.dart';
import '../models/portfolio_item.dart';
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
    String? userRole,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'user_role': userRole ?? 'freelancer', // По умолчанию фрилансер
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

  static Future<void> rejectApplication(int orderId, int applicationId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/applications/$applicationId/reject'),
      headers: headers,
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка отклонения отклика');
    }
  }

  // Алиас для совместимости
  static Future<List<OrderApplication>> getApplicationsForOrder(int orderId) {
    return getOrderApplications(orderId);
  }

  static Future<List<OrderApplication>> getApplicationsByFreelancer() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/my-applications'),
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

  // ==================== CHAT API ====================

  // Получить все чаты пользователя
  static Future<List<Chat>> getUserChats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final chatsList = data['data'] is List ? data['data'] : [data['data']];
        return chatsList.map<Chat>((json) => Chat.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки чатов');
    }
  }

  // Получить или создать чат для заказа
  static Future<Chat> getOrCreateChatForOrder(int orderId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/order/$orderId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Chat.fromJson(data['data']);
      }
      throw Exception('Не удалось получить чат');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка получения чата');
    }
  }

  // Получить сообщения чата
  static Future<List<Message>> getChatMessages(int chatId, {int limit = 50, int offset = 0}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/$chatId/messages?limit=$limit&offset=$offset'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final messagesList = data['data'] is List ? data['data'] : [data['data']];
        return messagesList.map<Message>((json) => Message.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки сообщений');
    }
  }

  // Отправить сообщение
  static Future<Message> sendMessage(int chatId, String message) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chat/$chatId/messages'),
      headers: headers,
      body: jsonEncode({'message': message}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Message.fromJson(data['data']);
      }
      throw Exception('Не удалось отправить сообщение');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка отправки сообщения');
    }
  }

  // Получить количество непрочитанных сообщений
  static Future<int> getUnreadMessagesCount() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/unread'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data']['unread_count'] ?? 0;
      }
      return 0;
    } else {
      return 0;
    }
  }

  // ==================== REVIEWS METHODS ====================

  // Создать отзыв для заказа
  static Future<Review> createReview(int orderId, int rating, String? comment) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/reviews/orders/$orderId/review'),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Review.fromJson(data['data']);
      }
      throw Exception('Не удалось создать отзыв');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания отзыва');
    }
  }

  // Получить отзывы пользователя
  static Future<List<Review>> getUserReviews(int userId, {int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/users/$userId/reviews?limit=$limit&offset=$offset'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final reviewsList = data['data'] is List ? data['data'] : [data['data']];
        return reviewsList.map<Review>((json) => Review.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Ошибка загрузки отзывов');
    }
  }

  // Получить статистику рейтинга пользователя
  static Future<UserRating> getUserRating(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/users/$userId/rating'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return UserRating.fromJson(data['data']);
      }
      throw Exception('Не удалось получить рейтинг');
    } else {
      throw Exception('Ошибка загрузки рейтинга');
    }
  }

  // Получить отзывы для заказа
  static Future<List<Review>> getOrderReviews(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/orders/$orderId/reviews'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final reviewsList = data['data'] is List ? data['data'] : [data['data']];
        return reviewsList.map<Review>((json) => Review.fromJson(json)).toList();
      }
      return [];
    } else {
      return [];
    }
  }

  // Обновить отзыв
  static Future<Review> updateReview(int reviewId, int rating, String? comment) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Review.fromJson(data['data']);
      }
      throw Exception('Не удалось обновить отзыв');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления отзыва');
    }
  }

  // Удалить отзыв
  static Future<void> deleteReview(int reviewId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления отзыва');
    }
  }

  // ==================== PORTFOLIO METHODS ====================

  // Создать работу в портфолио
  static Future<PortfolioItem> createPortfolioItem({
    required String title,
    String? description,
    String? imageUrl,
    String? projectUrl,
    String? category,
    List<String>? skills,
    DateTime? completedAt,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/portfolio'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'project_url': projectUrl,
        'category': category,
        'skills': skills,
        'completed_at': completedAt?.toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return PortfolioItem.fromJson(data['data']);
      }
      throw Exception('Не удалось создать работу');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка создания работы');
    }
  }

  // Получить портфолио пользователя
  static Future<List<PortfolioItem>> getUserPortfolio(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/portfolio/user/$userId'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final itemsList = data['data'] is List ? data['data'] : [data['data']];
        return itemsList.map<PortfolioItem>((json) => PortfolioItem.fromJson(json)).toList();
      }
      return [];
    } else {
      return [];
    }
  }

  // Обновить работу
  static Future<PortfolioItem> updatePortfolioItem({
    required int itemId,
    required String title,
    String? description,
    String? imageUrl,
    String? projectUrl,
    String? category,
    List<String>? skills,
    DateTime? completedAt,
    int? displayOrder,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/portfolio/$itemId'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'project_url': projectUrl,
        'category': category,
        'skills': skills,
        'completed_at': completedAt?.toIso8601String(),
        'display_order': displayOrder,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return PortfolioItem.fromJson(data['data']);
      }
      throw Exception('Не удалось обновить работу');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка обновления работы');
    }
  }

  // Удалить работу
  static Future<void> deletePortfolioItem(int itemId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/portfolio/$itemId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка удаления работы');
    }
  }

  // === ADMIN METHODS ===

  // Получить всех пользователей (только админ)
  static Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? role,
  }) async {
    final headers = await _getHeaders();
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    
    final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Ошибка получения пользователей');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка получения пользователей');
    }
  }

  // Получить статистику платформы (только админ)
  static Future<Map<String, dynamic>> getPlatformStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Ошибка получения статистики');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка получения статистики');
    }
  }

  // Верифицировать пользователя (только админ)
  static Future<void> verifyUser(int userId, String? note) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/verify'),
      headers: headers,
      body: jsonEncode({'verification_note': note}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка верификации пользователя');
    }
  }

  // Отменить верификацию пользователя (только админ)
  static Future<void> unverifyUser(int userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/unverify'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка отмены верификации');
    }
  }
}
