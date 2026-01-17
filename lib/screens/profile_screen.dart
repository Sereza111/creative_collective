import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../models/user.dart';
import '../services/export_service.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'forms/edit_profile_screen.dart';
import 'portfolio_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final financeAsync = ref.watch(balanceProvider);
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
            icon: const Icon(Icons.work_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PortfolioScreen(
                    userId: user.id,
                    isOwnProfile: true,
                  ),
                ),
              );
            },
            tooltip: 'Портфолио',
          ),
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
                      
                      // Имя пользователя с бейджем верификации
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Верифицированный пользователь',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Роль пользователя
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.userRole).withOpacity(0.2),
                          border: Border.all(
                            color: _getRoleColor(user.userRole),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(user.userRole),
                              size: 16,
                              color: _getRoleColor(user.userRole),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getRoleLabel(user.userRole).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getRoleColor(user.userRole),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Кнопки статистики и избранного
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/my_stats');
                              },
                              icon: const Icon(Icons.analytics, size: 18),
                              label: const Text(
                                'СТАТИСТИКА',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.electricBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/favorites');
                              },
                              icon: const Icon(Icons.favorite, size: 18),
                              label: const Text(
                                'ИЗБРАННОЕ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Кнопка админ-панели (только для админов)
                      if (user.userRole == 'admin') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin_panel');
                            },
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: const Text(
                              'АДМИН-ПАНЕЛЬ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Рейтинг
                      _RatingWidget(userId: user.id),
                      
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
                      
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Финансовая статистика
            if (financeAsync.isLoading)
              const SizedBox.shrink()
            else if (financeAsync.balance != null)
              AppTheme.fadeInAnimation(
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
                          currencyFormat.format(financeAsync.balance!.balance),
                          AppTheme.ghostWhite,
                        ),
                        const SizedBox(height: 12),
                        _buildFinanceRow(
                          'Заработано',
                          currencyFormat.format(financeAsync.balance!.totalEarned),
                          AppTheme.ashGray,
                        ),
                        const SizedBox(height: 12),
                        _buildFinanceRow(
                          'Потрачено',
                          currencyFormat.format(financeAsync.balance!.totalSpent),
                          AppTheme.ashGray,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            
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

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'client':
        return 'Заказчик';
      case 'freelancer':
        return 'Фрилансер';
      case 'admin':
        return 'Администратор';
      case 'manager':
        return 'Менеджер';
      case 'member':
        return 'Участник';
      default:
        return role ?? 'Пользователь';
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'client':
        return Icons.business_center_outlined;
      case 'freelancer':
        return Icons.engineering_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'client':
        return AppTheme.tombstoneWhite;
      case 'freelancer':
        return Colors.green;
      case 'admin':
        return AppTheme.bloodRed;
      default:
        return AppTheme.ashGray;
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
      final transactionsAsync = ref.read(transactionsProvider);
      final transactions = transactionsAsync.transactions;
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
      final transactionsAsync = ref.read(transactionsProvider);
      final transactions = transactionsAsync.transactions;
      
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

// Виджет для отображения рейтинга пользователя
class _RatingWidget extends ConsumerStatefulWidget {
  final int userId;

  const _RatingWidget({required this.userId});

  @override
  ConsumerState<_RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends ConsumerState<_RatingWidget> {
  bool _isLoading = true;
  double? _averageRating;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final rating = await ApiService.getUserRating(widget.userId);
      if (mounted) {
        setState(() {
          _averageRating = rating.averageRating;
          _reviewsCount = rating.reviewsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dimGray),
          ),
        ),
      );
    }

    if (_reviewsCount == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Нет отзывов',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.dimGray,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Звезды
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFullStar = _averageRating != null && starValue <= _averageRating!;
              final isHalfStar = _averageRating != null && 
                  starValue > _averageRating! && 
                  (starValue - 0.5) <= _averageRating!;
              
              return Icon(
                isFullStar
                    ? Icons.star
                    : isHalfStar
                        ? Icons.star_half
                        : Icons.star_border,
                size: 20,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(width: 8),
          // Средний рейтинг и количество отзывов
          Text(
            _averageRating != null
                ? '${_averageRating!.toStringAsFixed(1)} ($_reviewsCount)'
                : '($_reviewsCount)',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.ghostWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
