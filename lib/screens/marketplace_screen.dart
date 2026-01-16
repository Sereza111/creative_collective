import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import 'forms/create_order_screen.dart';
import 'order_detail_screen.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String? _selectedStatus;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final user = ref.watch(authProvider).user;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    final isClient = user?.userRole == 'client';
    
    // Фильтруем заказы по поисковому запросу
    final filteredOrders = _searchQuery.isEmpty
        ? ordersState.orders
        : ordersState.orders.where((order) {
            final query = _searchQuery.toLowerCase();
            return order.title.toLowerCase().contains(query) ||
                (order.description?.toLowerCase().contains(query) ?? false) ||
                (order.category?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('МАРКЕТПЛЕЙС'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтры',
          ),
        ],
      ),
      floatingActionButton: isClient
          ? FloatingActionButton.extended(
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
                'СОЗДАТЬ ЗАКАЗ',
                style: TextStyle(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              backgroundColor: AppTheme.tombstoneWhite,
              elevation: 8,
            )
          : null,
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppTheme.gothicTextField(
              controller: _searchController,
              hintText: 'Поиск заказов...',
              icon: Icons.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Список заказов
          Expanded(
            child: ordersState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
                    ),
                  )
                : ordersState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: AppTheme.bloodRed),
                            const SizedBox(height: 20),
                            Text(
                              'Ошибка: ${ordersState.error}',
                              style: TextStyle(color: AppTheme.tombstoneWhite),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => ref.read(ordersProvider.notifier).loadOrders(),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.mistGray),
                                const SizedBox(height: 20),
                                Text(
                                  _searchQuery.isNotEmpty 
                                      ? 'Ничего не найдено'
                                      : 'Нет доступных заказов',
                                  style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Попробуйте изменить запрос'
                                      : (isClient ? 'Создайте свой первый заказ' : 'Пока нет заказов'),
                                  style: TextStyle(color: AppTheme.mistGray),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(ordersProvider.notifier).loadOrders(
                                status: _selectedStatus,
                                category: _selectedCategory,
                              );
                            },
                            backgroundColor: AppTheme.shadowGray,
                            color: AppTheme.tombstoneWhite,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
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
          ),
        ],
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
                maxLines: 3,
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
                  const SizedBox(width: 20),
                ],
                if (order.deadline != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.mistGray),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd.MM.yyyy').format(order.deadline!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mistGray,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                if (order.category != null) ...[
                  Icon(Icons.category_outlined, size: 14, color: AppTheme.mistGray),
                  const SizedBox(width: 6),
                  Text(
                    order.category!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mistGray,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
            if (order.applicationsCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppTheme.ashGray),
                  const SizedBox(width: 6),
                  Text(
                    '${order.applicationsCount} откликов',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.ashGray,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ФИЛЬТРЫ',
          style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Статус',
                labelStyle: TextStyle(color: AppTheme.mistGray),
              ),
              dropdownColor: AppTheme.darkerCharcoal,
              items: [
                DropdownMenuItem(value: null, child: Text('Все', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'published', child: Text('Опубликован', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'in_progress', child: Text('В работе', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'completed', child: Text('Завершен', style: TextStyle(color: AppTheme.tombstoneWhite))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Категория',
                labelStyle: TextStyle(color: AppTheme.mistGray),
              ),
              dropdownColor: AppTheme.darkerCharcoal,
              items: [
                DropdownMenuItem(value: null, child: Text('Все', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'design', child: Text('Дизайн', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'development', child: Text('Разработка', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'content', child: Text('Контент', style: TextStyle(color: AppTheme.tombstoneWhite))),
                DropdownMenuItem(value: 'marketing', child: Text('Маркетинг', style: TextStyle(color: AppTheme.tombstoneWhite))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedCategory = null;
              });
              ref.read(ordersProvider.notifier).loadOrders();
              Navigator.pop(context);
            },
            child: Text('СБРОСИТЬ', style: TextStyle(color: AppTheme.mistGray)),
          ),
          TextButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).loadOrders(
                status: _selectedStatus,
                category: _selectedCategory,
              );
              Navigator.pop(context);
            },
            child: Text('ПРИМЕНИТЬ', style: TextStyle(color: AppTheme.tombstoneWhite)),
          ),
        ],
      ),
    );
  }
}

