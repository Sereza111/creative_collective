import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/transactions_provider.dart';
import '../models/user.dart';
import '../services/export_service.dart';
import 'auth/login_screen.dart';
import 'forms/edit_profile_screen.dart';

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
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context, ref),
            tooltip: 'Экспорт данных',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            tooltip: 'Редактировать',
          ),
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
            tooltip: 'Выход',
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
                        child: user.avatarUrl != null
                            ? Image.network(
                                user.avatarUrl!,
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
                        (user.fullName ?? user.email.split('@')[0]).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.ghostWhite,
                          letterSpacing: 2.0,
                          fontFamily: 'serif',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (user.fullName != null && user.email != user.fullName) ...[
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
                      if (user.createdAt != null) ...[
                        _buildInfoRow(
                          'Дата регистрации',
                          DateFormat('dd.MM.yyyy').format(user.createdAt!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (user.updatedAt != null) ...[
                        _buildInfoRow(
                          'Последнее обновление',
                          DateFormat('dd.MM.yyyy').format(user.updatedAt!),
                        ),
                        const SizedBox(height: 12),
                      ],
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

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ЭКСПОРТ ДАННЫХ',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption(
              context,
              ref,
              'Проекты',
              Icons.folder_outlined,
              () => _exportProjects(context, ref),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              ref,
              'Задачи',
              Icons.task_outlined,
              () => _exportTasks(context, ref),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              ref,
              'Транзакции',
              Icons.receipt_long_outlined,
              () => _exportTransactions(context, ref),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              context,
              ref,
              'Все данные',
              Icons.file_download_outlined,
              () => _exportAllData(context, ref),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ОТМЕНА',
              style: TextStyle(color: AppTheme.mistGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dimGray.withOpacity(0.3)),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.ashGray, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.tombstoneWhite,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.mistGray, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProjects(BuildContext context, WidgetRef ref) async {
    try {
      final projects = ref.read(projectsProvider).projects;
      final file = await ExportService.exportProjectsToCSV(projects);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Проекты экспортированы: ${file.path}'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }

  Future<void> _exportTasks(BuildContext context, WidgetRef ref) async {
    try {
      final tasks = ref.read(tasksProvider).tasks;
      final file = await ExportService.exportTasksToCSV(tasks);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Задачи экспортированы: ${file.path}'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }

  Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final transactions = ref.read(transactionsProvider).transactions;
      final file = await ExportService.exportTransactionsToCSV(transactions);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Транзакции экспортированы: ${file.path}'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData(BuildContext context, WidgetRef ref) async {
    try {
      final projects = ref.read(projectsProvider).projects;
      final tasks = ref.read(tasksProvider).tasks;
      final transactions = ref.read(transactionsProvider).transactions;
      
      final file = await ExportService.exportAllDataToCSV(
        projects: projects,
        tasks: tasks,
        transactions: transactions,
      );
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Все данные экспортированы: ${file.path}'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }
}
