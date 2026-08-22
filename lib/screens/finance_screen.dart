import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/user_balance.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workspace_components.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String? _filterType;
  String? _filterStatus;

  bool get _hasFilters => _filterType != null || _filterStatus != null;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(balanceProvider.notifier).refresh(),
      ref.read(transactionsProvider.notifier).loadTransactions(
            type: _filterType,
            status: _filterStatus,
          ),
    ]);
  }

  void _selectFilter(String value) {
    setState(() {
      if (value.startsWith('type_')) {
        _filterType = value == 'type_all' ? null : value.substring(5);
      } else {
        _filterStatus = value == 'status_all' ? null : value.substring(7);
      }
    });
    ref.read(transactionsProvider.notifier).loadTransactions(
          type: _filterType,
          status: _filterStatus,
        );
  }

  void _resetFilters() {
    setState(() {
      _filterType = null;
      _filterStatus = null;
    });
    ref.read(transactionsProvider.notifier).loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final transactionsState = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        actions: [
          IconButton(
            tooltip: 'Пополнить баланс',
            onPressed: () => Navigator.pushNamed(context, '/add_balance'),
            icon: const Icon(Icons.add_card_outlined),
          ),
          IconButton(
            tooltip: 'Вывести средства',
            onPressed: () => Navigator.pushNamed(context, '/withdrawal'),
            icon: const Icon(Icons.upload_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Фильтры транзакций',
            icon: const Icon(Icons.tune),
            onSelected: _selectFilter,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'type_all', child: Text('Все типы')),
              PopupMenuItem(value: 'type_income', child: Text('Доходы')),
              PopupMenuItem(value: 'type_expense', child: Text('Расходы')),
              PopupMenuItem(value: 'type_withdrawal', child: Text('Выводы')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'status_all', child: Text('Все статусы')),
              PopupMenuItem(
                value: 'status_completed',
                child: Text('Завершенные'),
              ),
              PopupMenuItem(
                value: 'status_pending',
                child: Text('В ожидании'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.goldenrod,
        backgroundColor: AppTheme.shadowGray,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: WorkspaceContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkspacePageIntro(
                  eyebrow: 'Расчеты пространства',
                  title: 'Деньги под контролем',
                  description:
                      'Баланс, движение средств и операции по заказам.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/withdrawal'),
                      icon: const Icon(Icons.north_east, size: 17),
                      label: const Text('Вывести'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/add_balance'),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('Пополнить'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (balanceState.isLoading && balanceState.balance == null)
                  const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (balanceState.error != null &&
                    balanceState.balance == null)
                  WorkspaceErrorState(
                    message: balanceState.error!,
                    onRetry: () => ref.read(balanceProvider.notifier).refresh(),
                  )
                else if (balanceState.balance != null)
                  _BalancePanel(balance: balanceState.balance!),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'История операций',
                        style: TextStyle(
                          color: AppTheme.tombstoneWhite,
                          fontFamily: 'Georgia',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_hasFilters)
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Сбросить фильтры'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (transactionsState.isLoading &&
                    transactionsState.transactions.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (transactionsState.error != null &&
                    transactionsState.transactions.isEmpty)
                  WorkspaceErrorState(
                    message: transactionsState.error!,
                    onRetry: () => ref
                        .read(transactionsProvider.notifier)
                        .loadTransactions(
                          type: _filterType,
                          status: _filterStatus,
                        ),
                  )
                else if (transactionsState.transactions.isEmpty)
                  const WorkspaceEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Транзакций пока нет',
                    message: 'Все операции по счету появятся в этом разделе.',
                  )
                else
                  ...transactionsState.transactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TransactionCard(transaction: transaction),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.balance});

  final UserBalance balance;

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    final available = balance.balance - balance.pendingAmount;

    return WorkspacePanel(
      accent: AppTheme.goldenrod,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final balanceBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ДОСТУПНО',
                style: TextStyle(
                  color: AppTheme.goldenrod,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                money.format(available),
                style: const TextStyle(
                  color: AppTheme.tombstoneWhite,
                  fontFamily: 'Georgia',
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${money.format(balance.pendingAmount)} ожидает завершения',
                style: const TextStyle(color: AppTheme.mistGray, fontSize: 11),
              ),
            ],
          );
          final stats = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _BalanceStat(
                label: 'Заработано',
                value: money.format(balance.totalEarned),
                color: AppTheme.gothicGreen,
              ),
              _BalanceStat(
                label: 'Потрачено',
                value: money.format(balance.totalSpent),
                color: AppTheme.bloodRed,
              ),
              _BalanceStat(
                label: 'Выведено',
                value: money.format(balance.totalWithdrawn),
                color: AppTheme.electricBlue,
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [balanceBlock, const SizedBox(height: 22), stats],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: balanceBlock),
              const SizedBox(width: 32),
              Flexible(flex: 2, child: stats),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.deepBlack,
        border: Border.all(color: AppTheme.dimGray),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.mistGray, fontSize: 10)),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionModel transaction;

  bool get _income =>
      transaction.type == 'income' || transaction.type == 'refund';

  Color get _typeColor => switch (transaction.type) {
        'income' => AppTheme.gothicGreen,
        'expense' => AppTheme.bloodRed,
        'commission' => AppTheme.goldenrod,
        'withdrawal' => AppTheme.electricBlue,
        'refund' => AppTheme.deepPurple,
        _ => AppTheme.ashGray,
      };

  IconData get _icon => switch (transaction.type) {
        'income' => Icons.south_west,
        'expense' => Icons.north_east,
        'commission' => Icons.percent,
        'withdrawal' => Icons.account_balance_outlined,
        'refund' => Icons.replay,
        _ => Icons.swap_horiz,
      };

  Color get _statusColor => switch (transaction.status) {
        'completed' => AppTheme.gothicGreen,
        'pending' => AppTheme.goldenrod,
        'cancelled' || 'refunded' => AppTheme.bloodRed,
        _ => AppTheme.ashGray,
      };

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return WorkspacePanel(
      accent: _typeColor,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              border: Border.all(color: _typeColor.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(_icon, color: _typeColor, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.trim().isNotEmpty == true
                      ? transaction.description!
                      : transaction.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${transaction.typeLabel} · ${DateFormat('dd.MM.yyyy HH:mm').format(transaction.displayDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppTheme.mistGray, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_income ? '+' : '-'}${money.format(transaction.amount)}',
                style: TextStyle(
                  color:
                      _income ? AppTheme.gothicGreen : AppTheme.tombstoneWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                transaction.statusLabel,
                style: TextStyle(color: _statusColor, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
