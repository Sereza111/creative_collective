import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  bool _isLoadingStats = true;
  bool _isLoadingUsers = true;
  String _searchQuery = '';
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await ApiService.getPlatformStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статистики: $e')),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService.getAllUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _roleFilter,
      );
      setState(() {
        _users = response['users'] ?? [];
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки пользователей: $e')),
        );
      }
    }
  }

  Future<void> _verifyUser(int userId, String userName) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _VerificationDialog(userName: userName),
    );

    if (note != null) {
      try {
        await ApiService.verifyUser(userId, note.isEmpty ? null : note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь верифицирован')),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка верификации: $e')),
          );
        }
      }
    }
  }

  Future<void> _unverifyUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить верификацию?'),
        content: const Text('Вы уверены, что хотите отменить верификацию этого пользователя?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.unverifyUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Верификация отменена')),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    // Проверка прав админа
    if (user?.userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ-панель')),
        body: const Center(
          child: Text('У вас нет прав для доступа к админ-панели'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
            Tab(icon: Icon(Icons.people), text: 'Пользователи'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('Ошибка загрузки статистики'));
    }

    final users = _stats!['users'] ?? {};
    final orders = _stats!['orders'] ?? {};
    final reviews = _stats!['reviews'] ?? {};
    final chats = _stats!['chats'] ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика платформы', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Пользователи
            _buildStatCard(
              'Пользователи',
              Icons.people,
              Colors.blue,
              [
                _StatItem('Всего', users['total_users']?.toString() ?? '0'),
                _StatItem('Заказчики', users['clients']?.toString() ?? '0'),
                _StatItem('Фрилансеры', users['freelancers']?.toString() ?? '0'),
                _StatItem('Верифицированы', users['verified_users']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 16),

            // Заказы
            _buildStatCard(
              'Заказы',
              Icons.work,
              Colors.green,
              [
                _StatItem('Всего', orders['total_orders']?.toString() ?? '0'),
                _StatItem('Открытые', orders['open_orders']?.toString() ?? '0'),
                _StatItem('В работе', orders['in_progress_orders']?.toString() ?? '0'),
                _StatItem('Завершенные', orders['completed_orders']?.toString() ?? '0'),
                _StatItem('Отмененные', orders['cancelled_orders']?.toString() ?? '0'),
                _StatItem('Средний бюджет', _formatMoney(orders['average_budget'])),
              ],
            ),
            const SizedBox(height: 16),

            // Отзывы
            _buildStatCard(
              'Отзывы',
              Icons.star,
              Colors.orange,
              [
                _StatItem('Всего отзывов', reviews['total_reviews']?.toString() ?? '0'),
                _StatItem('Средний рейтинг', _formatRating(reviews['average_rating'])),
              ],
            ),
            const SizedBox(height: 16),

            // Чаты
            _buildStatCard(
              'Чаты',
              Icons.chat,
              Colors.purple,
              [
                _StatItem('Всего чатов', chats['total_chats']?.toString() ?? '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, List<_StatItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Поиск',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onSubmitted: (_) => _loadUsers(),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _roleFilter,
                hint: const Text('Роль'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Все')),
                  DropdownMenuItem(value: 'client', child: Text('Заказчики')),
                  DropdownMenuItem(value: 'freelancer', child: Text('Фрилансеры')),
                  DropdownMenuItem(value: 'admin', child: Text('Админы')),
                ],
                onChanged: (value) {
                  setState(() => _roleFilter = value);
                  _loadUsers();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('Пользователи не найдены'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isVerified = user['is_verified'] == 1 || user['is_verified'] == true;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(user['full_name']?[0]?.toUpperCase() ?? 'U')
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(user['full_name'] ?? 'Без имени'),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['email'] ?? ''),
                                Text('Роль: ${_getRoleLabel(user['user_role'])}'),
                                if (user['average_rating'] != null)
                                  Text('⭐ ${user['average_rating']} (${user['reviews_count']} отзывов)'),
                              ],
                            ),
                            trailing: isVerified
                                ? IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Отменить верификацию',
                                    onPressed: () => _unverifyUser(user['id']),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: 'Верифицировать',
                                    onPressed: () => _verifyUser(user['id'], user['full_name'] ?? 'Пользователь'),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'client':
        return 'Заказчик';
      case 'freelancer':
        return 'Фрилансер';
      case 'admin':
        return 'Администратор';
      default:
        return role ?? 'Неизвестно';
    }
  }

  // Безопасное форматирование денег
  String _formatMoney(dynamic value) {
    if (value == null) return '0 ₽';
    try {
      final double amount = value is String ? double.parse(value) : value.toDouble();
      return '${amount.toStringAsFixed(0)} ₽';
    } catch (e) {
      return '0 ₽';
    }
  }

  // Безопасное форматирование рейтинга
  String _formatRating(dynamic value) {
    if (value == null) return '0.00';
    try {
      final double rating = value is String ? double.parse(value) : value.toDouble();
      return rating.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

class _VerificationDialog extends StatefulWidget {
  final String userName;

  const _VerificationDialog({required this.userName});

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Верифицировать ${widget.userName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Вы подтверждаете, что проверили этого пользователя?'),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Примечание (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _noteController.text),
          child: const Text('Верифицировать'),
        ),
      ],
    );
  }
}

