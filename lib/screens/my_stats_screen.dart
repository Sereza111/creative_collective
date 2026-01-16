import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MyStatsScreen extends ConsumerStatefulWidget {
  const MyStatsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyStatsScreen> createState() => _MyStatsScreenState();
}

class _MyStatsScreenState extends ConsumerState<MyStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      // Загружаем данные для статистики
      final orders = await ApiService.getOrders();
      final applications = await ApiService.getMyApplications();
      final reviews = await ApiService.getReviewsForUser(user.id);
      final portfolioItems = await ApiService.getPortfolioItems(user.id);

      Map<String, dynamic> stats = {};

      if (user.userRole == 'freelancer') {
        // Статистика для фрилансера
        stats = {
          'total_applications': applications.length,
          'accepted_applications': applications.where((a) => a['status'] == 'accepted').length,
          'rejected_applications': applications.where((a) => a['status'] == 'rejected').length,
          'pending_applications': applications.where((a) => a['status'] == 'pending').length,
          'completed_orders': orders.where((o) => o.status == 'completed' && o.acceptedFreelancerId == user.id).length,
          'active_orders': orders.where((o) => o.status == 'in_progress' && o.acceptedFreelancerId == user.id).length,
          'total_reviews': reviews.length,
          'average_rating': user.averageRating ?? 0.0,
          'portfolio_items': portfolioItems.length,
          'total_earned': _calculateTotalEarned(orders, user.id),
          'applications_data': applications,
          'orders_data': orders.where((o) => o.acceptedFreelancerId == user.id).toList(),
        };
      } else {
        // Статистика для заказчика
        final myOrders = orders.where((o) => o.clientId == user.id).toList();
        stats = {
          'total_orders': myOrders.length,
          'open_orders': myOrders.where((o) => o.status == 'open').length,
          'in_progress_orders': myOrders.where((o) => o.status == 'in_progress').length,
          'completed_orders': myOrders.where((o) => o.status == 'completed').length,
          'cancelled_orders': myOrders.where((o) => o.status == 'cancelled').length,
          'total_spent': _calculateTotalSpent(myOrders),
          'average_order_budget': _calculateAverageBudget(myOrders),
          'total_reviews_given': reviews.length,
          'orders_data': myOrders,
        };
      }

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статистики: $e')),
        );
      }
    }
  }

  double _calculateTotalEarned(List<dynamic> orders, int userId) {
    double total = 0;
    for (var order in orders) {
      if (order.acceptedFreelancerId == userId && order.status == 'completed') {
        total += order.budget;
      }
    }
    return total;
  }

  double _calculateTotalSpent(List<dynamic> orders) {
    double total = 0;
    for (var order in orders) {
      if (order.status == 'completed') {
        total += order.budget;
      }
    }
    return total;
  }

  double _calculateAverageBudget(List<dynamic> orders) {
    if (orders.isEmpty) return 0;
    double total = 0;
    for (var order in orders) {
      total += order.budget;
    }
    return total / orders.length;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('МОЯ СТАТИСТИКА')),
        body: const Center(child: Text('Пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('МОЯ СТАТИСТИКА'),
        backgroundColor: AppTheme.midnightBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      backgroundColor: AppTheme.midnightBlack,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite))
          : _stats == null
              ? const Center(child: Text('Ошибка загрузки'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        Text(
                          user.userRole == 'freelancer' ? 'СТАТИСТИКА ФРИЛАНСЕРА' : 'СТАТИСТИКА ЗАКАЗЧИКА',
                          style: TextStyle(
                            color: AppTheme.tombstoneWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Основные метрики
                        if (user.userRole == 'freelancer')
                          _buildFreelancerStats()
                        else
                          _buildClientStats(),

                        const SizedBox(height: 24),

                        // График активности (упрощенный)
                        _buildActivityChart(user),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFreelancerStats() {
    return Column(
      children: [
        // Заработок
        _buildStatCard(
          'ВСЕГО ЗАРАБОТАНО',
          '${NumberFormat('#,###').format(_stats!['total_earned'])} ₽',
          Icons.attach_money,
          AppTheme.goldenrod,
        ),
        const SizedBox(height: 16),

        // Отклики
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'ОТКЛИКОВ',
                '${_stats!['total_applications']}',
                Icons.send,
                AppTheme.electricBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'ПРИНЯТО',
                '${_stats!['accepted_applications']}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Заказы
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'В РАБОТЕ',
                '${_stats!['active_orders']}',
                Icons.work,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'ЗАВЕРШЕНО',
                '${_stats!['completed_orders']}',
                Icons.done_all,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Рейтинг и портфолио
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'РЕЙТИНГ',
                '${_stats!['average_rating'].toStringAsFixed(1)} ⭐',
                Icons.star,
                AppTheme.goldenrod,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'ПОРТФОЛИО',
                '${_stats!['portfolio_items']} работ',
                Icons.photo_library,
                AppTheme.ashGray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientStats() {
    return Column(
      children: [
        // Затраты
        _buildStatCard(
          'ВСЕГО ПОТРАЧЕНО',
          '${NumberFormat('#,###').format(_stats!['total_spent'])} ₽',
          Icons.account_balance_wallet,
          AppTheme.bloodRed,
        ),
        const SizedBox(height: 16),

        // Средний бюджет
        _buildStatCard(
          'СРЕДНИЙ БЮДЖЕТ ЗАКАЗА',
          '${NumberFormat('#,###').format(_stats!['average_order_budget'])} ₽',
          Icons.trending_up,
          AppTheme.electricBlue,
        ),
        const SizedBox(height: 16),

        // Заказы по статусу
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'ВСЕГО',
                '${_stats!['total_orders']}',
                Icons.shopping_bag,
                AppTheme.tombstoneWhite,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'ОТКРЫТЫЕ',
                '${_stats!['open_orders']}',
                Icons.lock_open,
                AppTheme.electricBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'В РАБОТЕ',
                '${_stats!['in_progress_orders']}',
                Icons.work,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                'ЗАВЕРШЕНО',
                '${_stats!['completed_orders']}',
                Icons.done_all,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGray,
          border: Border.all(color: AppTheme.ashGray, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.mistGray,
                fontSize: 12,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGray,
          border: Border.all(color: AppTheme.ashGray, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.mistGray,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.tombstoneWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(user) {
    // Упрощенная визуализация активности
    final ordersData = _stats!['orders_data'] as List;
    final last7Days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return DateFormat('dd.MM').format(date);
    });

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGray,
          border: Border.all(color: AppTheme.ashGray, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'АКТИВНОСТЬ ЗА НЕДЕЛЮ',
              style: TextStyle(
                color: AppTheme.tombstoneWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: last7Days.map((day) {
                // Подсчет активности за день (упрощенно)
                final height = (ordersData.length * 10.0).clamp(20.0, 100.0);
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.electricBlue.withOpacity(0.7),
                        border: Border.all(color: AppTheme.electricBlue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: TextStyle(
                        color: AppTheme.mistGray,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.userRole == 'freelancer' 
                    ? 'График показывает завершенные заказы'
                    : 'График показывает созданные заказы',
                style: TextStyle(
                  color: AppTheme.mistGray,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

