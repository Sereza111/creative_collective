import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ГЛАВНАЯ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.fadeInAnimation(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.gothicTitle('Денис'),
                  const SizedBox(height: 16),
                  Text(
                    'Creative Collective',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.mistGray,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            AppTheme.gothicDivider(),
            const SizedBox(height: 48),
            
            // Статистика
            AppTheme.slideUpAnimation(
              child: _buildStatCard(
                context,
                'Активные задачи',
                '5',
                Icons.circle_outlined,
              ),
            ),
            const SizedBox(height: 20),
            AppTheme.slideUpAnimation(
              duration: const Duration(milliseconds: 900),
              child: _buildStatCard(
                context,
                'Баланс',
                '₽ 45,000',
                Icons.square_outlined,
              ),
            ),
            const SizedBox(height: 20),
            AppTheme.slideUpAnimation(
              duration: const Duration(milliseconds: 1000),
              child: _buildStatCard(
                context,
                'Проекты',
                '3',
                Icons.change_history_outlined,
              ),
            ),
            
            const SizedBox(height: 48),
            AppTheme.gothicDivider(),
            const SizedBox(height: 48),
            
            // Действия
            AppTheme.fadeInAnimation(
              duration: const Duration(milliseconds: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTheme.gothicButton(
                    text: 'Dashboard',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  AppTheme.gothicButton(
                    text: 'Новый проект',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Создание проекта...'),
                          backgroundColor: AppTheme.shadowGray,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.dimGray.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, color: AppTheme.ashGray, size: 24),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.tombstoneWhite,
                        fontFamily: 'serif',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
