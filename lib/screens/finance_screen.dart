import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ФИНАНСЫ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавить транзакцию'),
                  backgroundColor: AppTheme.shadowGray,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Баланс
            AppTheme.fadeInAnimation(
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
                        '₽ 45,250',
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
                          _buildBalanceInfo('Заработано', '₽ 125,000'),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppTheme.dimGray.withOpacity(0.3),
                          ),
                          _buildBalanceInfo('Потрачено', '₽ 79,750'),
                        ],
                      ),
                    ],
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
            
            AppTheme.slideUpAnimation(
              offset: 15,
              child: _buildTransactionItem(
                'Оплата проекта "Видеоклип"',
                '+₽ 8,000',
                '15.12.2025',
                true,
              ),
            ),
            const SizedBox(height: 12),
            
            AppTheme.slideUpAnimation(
              offset: 15,
              duration: const Duration(milliseconds: 900),
              child: _buildTransactionItem(
                'Бонус за выполнение',
                '+₽ 500',
                '14.12.2025',
                true,
              ),
            ),
            const SizedBox(height: 12),
            
            AppTheme.slideUpAnimation(
              offset: 15,
              duration: const Duration(milliseconds: 1000),
              child: _buildTransactionItem(
                'Adobe Creative Cloud',
                '-₽ 2,000',
                '12.12.2025',
                false,
              ),
            ),
            const SizedBox(height: 12),
            
            AppTheme.slideUpAnimation(
              offset: 15,
              duration: const Duration(milliseconds: 1100),
              child: _buildTransactionItem(
                'Оплата за анимацию',
                '+₽ 12,500',
                '10.12.2025',
                true,
              ),
            ),
            const SizedBox(height: 12),
            
            AppTheme.slideUpAnimation(
              offset: 15,
              duration: const Duration(milliseconds: 1200),
              child: _buildTransactionItem(
                'Покупка плагинов',
                '-₽ 1,500',
                '08.12.2025',
                false,
              ),
            ),
          ],
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
