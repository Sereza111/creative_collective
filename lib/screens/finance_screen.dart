import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart' as app_transaction;
import 'forms/add_transaction_screen.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ФИНАНСЫ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(financeProvider.notifier).refresh();
          await ref.read(transactionsProvider.notifier).refresh();
        },
        backgroundColor: AppTheme.charcoal,
        color: AppTheme.ghostWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Баланс
              financeAsync.when(
                data: (finance) {
                  if (finance == null) {
                    return const Center(child: Text('Нет данных'));
                  }
                  return AppTheme.fadeInAnimation(
                    child: AppTheme.animatedGothicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'БАЛАНС',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.mistGray,
                                letterSpacing: 3.0,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              currencyFormat.format(finance.balance),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w200,
                                color: AppTheme.ghostWhite,
                                fontFamily: 'serif',
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              height: 1,
                              color: AppTheme.dimGray.withOpacity(0.3),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBalanceInfo('Заработано', currencyFormat.format(finance.totalEarned)),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: AppTheme.dimGray.withOpacity(0.3),
                                ),
                                _buildBalanceInfo('Потрачено', currencyFormat.format(finance.totalSpent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => AppTheme.animatedGothicCard(
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.ashGray)),
                  ),
                ),
                error: (error, stack) => AppTheme.animatedGothicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Ошибка загрузки: $error',
                        style: const TextStyle(color: AppTheme.bloodRed),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              AppTheme.gothicDivider(),
              const SizedBox(height: 48),
              
              // История
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  'ИСТОРИЯ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.ashGray,
                    letterSpacing: 4.0,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return AppTheme.animatedGothicCard(
                      child: const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'НЕТ ТРАНЗАКЦИЙ',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.mistGray,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: transactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final transaction = entry.value;
                      final dateFormat = DateFormat('dd.MM.yyyy');
                      final amountText = transaction.isPositive 
                        ? '+${currencyFormat.format(transaction.amount)}'
                        : '-${currencyFormat.format(transaction.amount)}';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppTheme.slideUpAnimation(
                          offset: 15,
                          duration: Duration(milliseconds: 800 + (index * 100)),
                          child: _buildTransactionItem(
                            transaction.description ?? transaction.category ?? 'Транзакция',
                            amountText,
                            dateFormat.format(transaction.date),
                            transaction.isPositive,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.ashGray),
                  ),
                ),
                error: (error, stack) => AppTheme.animatedGothicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Ошибка загрузки транзакций',
                        style: const TextStyle(color: AppTheme.bloodRed),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: AppTheme.mistGray,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppTheme.ashGray,
            fontFamily: 'serif',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String amount,
    String date,
    bool isPositive,
  ) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.dimGray.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                color: AppTheme.ashGray,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.tombstoneWhite,
                      letterSpacing: 1.0,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.mistGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: AppTheme.ashGray,
                fontFamily: 'serif',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
