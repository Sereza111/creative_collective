import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String? _filterType;
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final transactionsState = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ФИНАНСЫ'),
        actions: [
          // Фильтры
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith('type_')) {
                  _filterType = value == 'type_all' ? null : value.replaceFirst('type_', '');
                } else if (value.startsWith('status_')) {
                  _filterStatus = value == 'status_all' ? null : value.replaceFirst('status_', '');
                }
              });
              ref.read(transactionsProvider.notifier).loadTransactions(
                type: _filterType,
                status: _filterStatus,
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'type_all',
                child: Text('Все типы'),
              ),
              const PopupMenuItem(
                value: 'type_income',
                child: Text('Доходы'),
              ),
              const PopupMenuItem(
                value: 'type_expense',
                child: Text('Расходы'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'status_all',
                child: Text('Все статусы'),
              ),
              const PopupMenuItem(
                value: 'status_completed',
                child: Text('Завершенные'),
              ),
              const PopupMenuItem(
                value: 'status_pending',
                child: Text('В ожидании'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(balanceProvider.notifier).refresh();
          await ref.read(transactionsProvider.notifier).refresh();
        },
        backgroundColor: AppTheme.shadowGray,
        color: AppTheme.tombstoneWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Баланс
              if (balanceState.isLoading)
                Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite))
              else if (balanceState.balance != null)
                _buildBalanceCard(balanceState.balance!, currencyFormat),

              const SizedBox(height: 32),

              // Заголовок транзакций
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppTheme.gothicTitle('ТРАНЗАКЦИИ'),
                  if (_filterType != null || _filterStatus != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterType = null;
                          _filterStatus = null;
                        });
                        ref.read(transactionsProvider.notifier).loadTransactions();
                      },
                      child: Text(
                        'СБРОСИТЬ',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.mistGray,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Список транзакций
              if (transactionsState.isLoading)
                Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite))
              else if (transactionsState.transactions.isEmpty)
                _buildEmptyState()
              else
                ...transactionsState.transactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTransactionCard(transaction, currencyFormat),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(balance, NumberFormat currencyFormat) {
    final availableBalance = balance.balance - balance.pendingAmount;

    return AppTheme.fadeInAnimation(
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Основной баланс
              Text(
                'ДОСТУПНЫЙ БАЛАНС',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.mistGray,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currencyFormat.format(availableBalance),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                  color: AppTheme.tombstoneWhite,
                  fontFamily: 'serif',
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 32),
              AppTheme.gothicDivider(),
              const SizedBox(height: 24),

              // Статистика в два ряда
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'ЗАРАБОТАНО',
                      currencyFormat.format(balance.totalEarned),
                      AppTheme.gothicGreen,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.dimGray.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'ПОТРАЧЕНО',
                      currencyFormat.format(balance.totalSpent),
                      AppTheme.bloodRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'ВЫВЕДЕНО',
                      currencyFormat.format(balance.totalWithdrawn),
                      AppTheme.goldenrod,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.dimGray.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'В ОЖИДАНИИ',
                      currencyFormat.format(balance.pendingAmount),
                      AppTheme.electricBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.mistGray,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, NumberFormat currencyFormat) {
    final isIncome = transaction.type == 'income' || transaction.type == 'refund';
    final color = _getTransactionColor(transaction.type);

    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.typeLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.tombstoneWhite,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (transaction.description != null)
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.ashGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.dimGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Сумма
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isIncome ? AppTheme.gothicGreen : AppTheme.bloodRed,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.2),
                    border: Border.all(color: _getStatusColor(transaction.status)),
                  ),
                  child: Text(
                    transaction.statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: _getStatusColor(transaction.status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppTheme.dimGray,
            ),
            const SizedBox(height: 24),
            Text(
              'НЕТ ТРАНЗАКЦИЙ',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mistGray,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Все транзакции отобразятся здесь',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.dimGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return AppTheme.gothicGreen;
      case 'expense':
        return AppTheme.bloodRed;
      case 'commission':
        return AppTheme.goldenrod;
      case 'withdrawal':
        return AppTheme.electricBlue;
      case 'refund':
        return AppTheme.gothicBlue;
      default:
        return AppTheme.ashGray;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.add_circle_outline;
      case 'expense':
        return Icons.remove_circle_outline;
      case 'commission':
        return Icons.percent;
      case 'withdrawal':
        return Icons.arrow_upward;
      case 'refund':
        return Icons.refresh;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.gothicGreen;
      case 'pending':
        return AppTheme.goldenrod;
      case 'cancelled':
      case 'refunded':
        return AppTheme.bloodRed;
      default:
        return AppTheme.ashGray;
    }
  }
}
