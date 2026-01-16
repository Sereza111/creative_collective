import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/order_application.dart';
import '../providers/auth_provider.dart';
import 'order_detail_screen.dart';
import '../providers/orders_provider.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  List<OrderApplication> _applications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final applications = await ApiService.getApplicationsByFreelancer();
      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('МОИ ОТКЛИКИ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.bloodRed),
                      const SizedBox(height: 20),
                      Text(
                        'Ошибка: $_error',
                        style: TextStyle(color: AppTheme.tombstoneWhite),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_outlined, size: 64, color: AppTheme.mistGray),
                          const SizedBox(height: 20),
                          Text(
                            'У вас пока нет откликов',
                            style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Откликнитесь на заказ в маркетплейсе',
                            style: TextStyle(color: AppTheme.mistGray),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      backgroundColor: AppTheme.shadowGray,
                      color: AppTheme.tombstoneWhite,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final application = _applications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AppTheme.slideUpAnimation(
                              offset: 15,
                              duration: Duration(milliseconds: 800 + (index * 100)),
                              child: _buildApplicationCard(application, currencyFormat),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildApplicationCard(OrderApplication application, NumberFormat currencyFormat) {
    Color statusColor;
    IconData statusIcon;
    
    switch (application.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = AppTheme.bloodRed;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppTheme.ashGray;
        statusIcon = Icons.schedule;
    }

    return AppTheme.animatedGothicCard(
      child: InkWell(
        onTap: () async {
          // Находим заказ по orderId
          final ordersState = ref.read(ordersProvider);
          final order = ordersState.orders.firstWhere(
            (o) => o.id == application.orderId,
            orElse: () => ordersState.orders.first, // fallback
          );
          
          if (order != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.getStatusLabel().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(application.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mistGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Заказ #${application.orderId}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.tombstoneWhite,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (application.message != null && application.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.shadowGray.withOpacity(0.3),
                    border: Border.all(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  child: Text(
                    application.message!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.ashGray,
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (application.proposedBudget != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: AppTheme.ashGray),
                    const SizedBox(width: 6),
                    Text(
                      'Ваше предложение: ${currencyFormat.format(application.proposedBudget)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.ashGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

