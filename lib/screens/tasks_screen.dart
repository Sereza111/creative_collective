import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ЗАДАЧИ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавить задачу'),
                  backgroundColor: AppTheme.shadowGray,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTheme.fadeInAnimation(
            child: AppTheme.gothicTitle('Текущие'),
          ),
          const SizedBox(height: 32),
          AppTheme.gothicDivider(),
          const SizedBox(height: 32),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            child: _buildTaskCard(
              context,
              'Создать биту для видеоклипа',
              'В работе',
              '2025-12-15',
              3,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 900),
            child: _buildTaskCard(
              context,
              'Записать вокал',
              'Ожидает',
              '2025-12-20',
              5,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 1000),
            child: _buildTaskCard(
              context,
              'Микс и мастеринг',
              'Завершено',
              '2025-12-10',
              2,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 1100),
            child: _buildTaskCard(
              context,
              'Цветокоррекция видео',
              'В работе',
              '2025-12-18',
              4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    String title,
    String status,
    String dueDate,
    int priority,
  ) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.tombstoneWhite,
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppTheme.gothicBadge(status),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Дедлайн', dueDate),
                _buildInfoItem('Приоритет', priority.toString()),
              ],
            ),
            const SizedBox(height: 20),
            // Прогресс
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ПРОГРЕСС',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      status == 'Завершено' ? '100%' : status == 'В работе' ? '65%' : '0%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.ashGray,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.shadowGray.withOpacity(0.3),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: status == 'Завершено' ? 1.0 : status == 'В работе' ? 0.65 : 0.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.ashGray,
                        borderRadius: BorderRadius.zero,
                      ),
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

  Widget _buildInfoItem(String label, String value) {
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
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: AppTheme.ashGray,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
