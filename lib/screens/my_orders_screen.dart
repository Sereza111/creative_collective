import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import 'order_detail_screen.dart';
import 'forms/create_order_screen.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersProvider);
    final user = ref.watch(authProvider).user;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    // Фильтруем только заказы текущего пользователя
    final myOrders = ordersState.orders.where((order) => order.clientId == user?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('МОИ ЗАКАЗЫ'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          );
          if (result == true) {
            ref.read(ordersProvider.notifier).loadOrders();
          }
        },
        icon: const Icon(Icons.add, color: AppTheme.charcoal),
        label: const Text(
          'СОЗДАТЬ',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.tombstoneWhite,
        elevation: 8,
      ),
      body: ordersState.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
              ),
            )
          : myOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.mistGray),
                      const SizedBox(height: 20),
                      Text(
                        'У вас пока нет заказов',
                        style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Создайте свой первый заказ',
                        style: TextStyle(color: AppTheme.mistGray),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(ordersProvider.notifier).loadOrders();
                  },
                  backgroundColor: AppTheme.shadowGray,
                  color: AppTheme.tombstoneWhite,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: myOrders.length,
                    itemBuilder: (context, index) {
                      final order = myOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppTheme.slideUpAnimation(
                          offset: 15,
                          duration: Duration(milliseconds: 800 + (index * 100)),
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(order: order),
                                ),
                              );
                              if (result == true) {
                                ref.read(ordersProvider.notifier).loadOrders();
                              }
                            },
                            child: _buildOrderCard(order, currencyFormat),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderCard(order, NumberFormat currencyFormat) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.tombstoneWhite,
                      letterSpacing: 2.5,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                AppTheme.gothicBadge(order.getStatusLabel()),
              ],
            ),
            const SizedBox(height: 16),
            if (order.description != null && order.description!.isNotEmpty) ...[
              Text(
                order.description!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.mistGray,
                  height: 1.6,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (order.budget != null) ...[
                  Icon(Icons.attach_money, size: 16, color: AppTheme.ashGray),
                  const SizedBox(width: 6),
                  Text(
                    currencyFormat.format(order.budget),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.ashGray,
                    ),
                  ),
                  const Spacer(),
                ],
                if (order.applicationsCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bloodRed.withOpacity(0.2),
                      border: Border.all(color: AppTheme.bloodRed),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: AppTheme.bloodRed),
                        const SizedBox(width: 6),
                        Text(
                          '${order.applicationsCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.bloodRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (order.freelancerName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.engineering_outlined, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Исполнитель: ${order.freelancerName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

