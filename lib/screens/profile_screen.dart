import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../models/user.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final financeAsync = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    if (authState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ПРОФИЛЬ')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.ashGray),
        ),
      );
    }

    if (authState.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ПРОФИЛЬ')),
        body: const Center(
          child: Text(
            'ПОЛЬЗОВАТЕЛЬ НЕ НАЙДЕН',
            style: TextStyle(color: AppTheme.mistGray),
          ),
        ),
      );
    }

    final user = authState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ПРОФИЛЬ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватар и основная информация
            AppTheme.fadeInAnimation(
              child: AppTheme.animatedGothicCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Аватар
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.darkerCharcoal,
                          border: Border.all(
                            color: AppTheme.dimGray.withOpacity(0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: user.avatar != null
                            ? Image.network(
                                user.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.mistGray,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.mistGray,
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Имя пользователя
                      Text(
                        user.username.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.ghostWhite,
                          letterSpacing: 2.0,
                          fontFamily: 'serif',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (user.fullName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.fullName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.mistGray,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.ashGray,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Роль
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.dimGray.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          _getRoleLabel(user.role).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.ashGray,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Финансовая статистика
            financeAsync.when(
              data: (finance) {
                if (finance == null) return const SizedBox.shrink();
                
                return AppTheme.fadeInAnimation(
                  duration: const Duration(milliseconds: 900),
                  child: AppTheme.animatedGothicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ФИНАНСЫ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.mistGray,
                              letterSpacing: 3.0,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFinanceRow(
                            'Баланс',
                            currencyFormat.format(finance.balance),
                            AppTheme.ghostWhite,
                          ),
                          const SizedBox(height: 12),
                          _buildFinanceRow(
                            'Заработано',
                            currencyFormat.format(finance.totalEarned),
                            AppTheme.ashGray,
                          ),
                          const SizedBox(height: 12),
                          _buildFinanceRow(
                            'Потрачено',
                            currencyFormat.format(finance.totalSpent),
                            AppTheme.ashGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            
            // Информация об аккаунте
            AppTheme.fadeInAnimation(
              duration: const Duration(milliseconds: 1100),
              child: AppTheme.animatedGothicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ИНФОРМАЦИЯ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.mistGray,
                          letterSpacing: 3.0,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        'Дата регистрации',
                        DateFormat('dd.MM.yyyy').format(user.createdAt),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Последнее обновление',
                        DateFormat('dd.MM.yyyy').format(user.updatedAt),
                      ),
                      if (user.lastLogin != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Последний вход',
                          DateFormat('dd.MM.yyyy HH:mm').format(user.lastLogin!),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Статус',
                        user.isActive ? 'Активен' : 'Неактивен',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Кнопка выхода
            AppTheme.fadeInAnimation(
              duration: const Duration(milliseconds: 1300),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.bloodRed.withOpacity(0.5)),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'ВЫЙТИ ИЗ АККАУНТА',
                    style: TextStyle(
                      color: AppTheme.bloodRed,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: AppTheme.mistGray,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: valueColor,
            fontFamily: 'serif',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            color: AppTheme.mistGray,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: AppTheme.ashGray,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'manager':
        return 'Менеджер';
      case 'member':
        return 'Участник';
      default:
        return role;
    }
  }
}
