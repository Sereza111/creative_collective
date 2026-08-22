import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workspace_components.dart';
import 'forms/create_order_screen.dart';
import 'order_detail_screen.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date_desc';
  String? _selectedStatus;
  String? _selectedCategory;
  double? _minBudget;
  double? _maxBudget;
  DateTime? _maxDeadline;

  int get _activeFilterCount => [
        _selectedStatus,
        _selectedCategory,
        _minBudget,
        _maxBudget,
        _maxDeadline,
      ].where((value) => value != null).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
    );
    if (result == true && mounted) {
      await ref.read(ordersProvider.notifier).loadOrders();
    }
  }

  List<Order> _filterAndSort(List<Order> source) {
    var orders = [...source];
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      orders = orders.where((order) {
        return order.title.toLowerCase().contains(query) ||
            (order.description?.toLowerCase().contains(query) ?? false) ||
            (order.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    orders = orders.where((order) {
      if ((_minBudget != null || _maxBudget != null) && order.budget == null) {
        return false;
      }
      if (_minBudget != null && order.budget! < _minBudget!) return false;
      if (_maxBudget != null && order.budget! > _maxBudget!) return false;
      if (_maxDeadline != null) {
        if (order.deadline == null) return false;
        if (order.deadline!.isAfter(_maxDeadline!)) return false;
      }
      return true;
    }).toList();

    orders.sort((a, b) => switch (_sortBy) {
          'date_asc' => a.createdAt.compareTo(b.createdAt),
          'budget_desc' => (b.budget ?? 0).compareTo(a.budget ?? 0),
          'budget_asc' => (a.budget ?? 0).compareTo(b.budget ?? 0),
          'deadline_asc' => _compareDeadlines(a.deadline, b.deadline),
          _ => b.createdAt.compareTo(a.createdAt),
        });
    return orders;
  }

  int _compareDeadlines(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final isClient = ref.watch(authProvider).user?.userRole == 'client';
    final orders = _filterAndSort(state.orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Маркет'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Сортировка',
            icon: const Icon(Icons.sort),
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date_desc', child: Text('Сначала новые')),
              PopupMenuItem(value: 'date_asc', child: Text('Сначала старые')),
              PopupMenuItem(value: 'budget_desc', child: Text('Бюджет: выше')),
              PopupMenuItem(value: 'budget_asc', child: Text('Бюджет: ниже')),
              PopupMenuItem(
                value: 'deadline_asc',
                child: Text('Ближайший срок'),
              ),
            ],
          ),
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: IconButton(
              tooltip: 'Фильтры',
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: WorkspaceContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspacePageIntro(
              eyebrow: 'Открытые предложения',
              title: 'Работа на ваших условиях',
              description: 'Заказы, бюджеты и сроки без перегруженной витрины.',
              actions: [
                if (isClient)
                  ElevatedButton.icon(
                    onPressed: _openCreateOrder,
                    icon: const Icon(Icons.add_business_outlined, size: 18),
                    label: const Text('Создать заказ'),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            WorkspaceSearchField(
              controller: _searchController,
              hintText: 'Найти заказ, направление или услугу',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 16, color: AppTheme.goldenrod),
                  const SizedBox(width: 7),
                  Text(
                    'Активных фильтров: $_activeFilterCount',
                    style: const TextStyle(
                      color: AppTheme.ashGray,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                      onPressed: _resetFilters, child: const Text('Сбросить')),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Expanded(child: _buildContent(state, orders, isClient)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrdersState state, List<Order> orders, bool isClient) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
      return WorkspaceErrorState(
        message: state.error!,
        onRetry: () => ref.read(ordersProvider.notifier).loadOrders(),
      );
    }
    if (orders.isEmpty) {
      final narrowed = _searchQuery.trim().isNotEmpty || _activeFilterCount > 0;
      return WorkspaceEmptyState(
        icon: narrowed ? Icons.search_off : Icons.storefront_outlined,
        title: narrowed ? 'Подходящих заказов нет' : 'Заказов пока нет',
        message: narrowed
            ? 'Измените запрос или параметры фильтра.'
            : isClient
                ? 'Опубликуйте задачу и начните собирать отклики.'
                : 'Новые предложения появятся здесь.',
        action: isClient && !narrowed
            ? ElevatedButton.icon(
                onPressed: _openCreateOrder,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Создать заказ'),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(
            status: _selectedStatus,
            category: _selectedCategory,
          ),
      color: AppTheme.goldenrod,
      backgroundColor: AppTheme.shadowGray,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 620,
          mainAxisExtent: 226,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: orders.length,
        itemBuilder: (_, index) => _OrderCard(
          order: orders[index],
          onOpen: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: orders[index]),
              ),
            );
            if (result == true && mounted) {
              await ref.read(ordersProvider.notifier).loadOrders();
            }
          },
        ),
      ),
    );
  }

  Future<void> _resetFilters() async {
    setState(() {
      _selectedStatus = null;
      _selectedCategory = null;
      _minBudget = null;
      _maxBudget = null;
      _maxDeadline = null;
    });
    await ref.read(ordersProvider.notifier).loadOrders();
  }

  Future<void> _showFilterDialog() async {
    final minController =
        TextEditingController(text: _minBudget?.toString() ?? '');
    final maxController =
        TextEditingController(text: _maxBudget?.toString() ?? '');
    var status = _selectedStatus;
    var category = _selectedCategory;
    var deadline = _maxDeadline;

    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Фильтры заказов'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Статус'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все статусы')),
                      DropdownMenuItem(
                          value: 'published', child: Text('Опубликован')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('В работе')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Завершен')),
                    ],
                    onChanged: (value) => setDialogState(() => status = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    items: const [
                      DropdownMenuItem(
                          value: null, child: Text('Все категории')),
                      DropdownMenuItem(value: 'design', child: Text('Дизайн')),
                      DropdownMenuItem(
                          value: 'development', child: Text('Разработка')),
                      DropdownMenuItem(
                          value: 'content', child: Text('Контент')),
                      DropdownMenuItem(
                          value: 'marketing', child: Text('Маркетинг')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => category = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Бюджет от'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          decoration:
                              const InputDecoration(labelText: 'Бюджет до'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Срок не позднее'),
                    subtitle: Text(
                      deadline == null
                          ? 'Любая дата'
                          : DateFormat('dd.MM.yyyy').format(deadline!),
                    ),
                    trailing: deadline == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Сбросить срок',
                            onPressed: () =>
                                setDialogState(() => deadline = null),
                            icon: const Icon(Icons.close),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deadline ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null)
                        setDialogState(() => deadline = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );

    if (apply == true && mounted) {
      setState(() {
        _selectedStatus = status;
        _selectedCategory = category;
        _minBudget = double.tryParse(minController.text.replaceAll(',', '.'));
        _maxBudget = double.tryParse(maxController.text.replaceAll(',', '.'));
        _maxDeadline = deadline;
      });
      await ref.read(ordersProvider.notifier).loadOrders(
            status: status,
            category: category,
          );
    }
    minController.dispose();
    maxController.dispose();
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onOpen});

  final Order order;
  final VoidCallback onOpen;

  Color get _accent => switch (order.status) {
        'published' => AppTheme.gothicGreen,
        'in_progress' => AppTheme.electricBlue,
        'review' => AppTheme.goldenrod,
        'completed' => AppTheme.deepPurple,
        'cancelled' => AppTheme.bloodRed,
        _ => AppTheme.ashGray,
      };

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return WorkspacePanel(
      accent: _accent,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.09),
                  border: Border.all(color: _accent),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  order.getStatusLabel(),
                  style: TextStyle(color: _accent, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.description?.trim().isNotEmpty == true
                ? order.description!
                : 'Описание заказа не добавлено',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ashGray,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _OrderMeta(
                icon: Icons.payments_outlined,
                value: order.budget == null
                    ? 'Бюджет не указан'
                    : money.format(order.budget),
                color: AppTheme.goldenrod,
              ),
              _OrderMeta(
                icon: Icons.event_outlined,
                value: order.deadline == null
                    ? 'Срок не указан'
                    : DateFormat('dd.MM.yyyy').format(order.deadline!),
              ),
              if (order.category != null)
                _OrderMeta(
                    icon: Icons.category_outlined, value: order.category!),
              _OrderMeta(
                icon: Icons.people_outline,
                value: '${order.applicationsCount} откликов',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.value, this.color});

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppTheme.mistGray;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: itemColor),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: itemColor, fontSize: 11)),
      ],
    );
  }
}
