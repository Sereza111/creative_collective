import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import 'forms/edit_profile_screen.dart';
import 'portfolio_screen.dart';

class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final finance = ref.watch(balanceProvider);
    final user = auth.user;

    if (auth.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip: 'Портфолио',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PortfolioScreen(
                  userId: user.id,
                  isOwnProfile: true,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Экспорт данных',
            onPressed: () => _showExportSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Редактировать профиль',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 700 ? 16 : 28,
          24,
          MediaQuery.sizeOf(context).width < 700 ? 16 : 28,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЛИЧНОЕ ДОСЬЕ',
                  style: TextStyle(
                    color: AppTheme.goldenrod,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Профиль участника',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 22),
                _IdentityPanel(user: user),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final financePanel = _FinancePanel(
                      loading: finance.isLoading,
                      balance: finance.balance?.balance,
                      earned: finance.balance?.totalEarned,
                      spent: finance.balance?.totalSpent,
                    );
                    final accountPanel = _AccountPanel(user: user);
                    if (constraints.maxWidth >= 850) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: financePanel),
                          const SizedBox(width: 16),
                          Expanded(child: accountPanel),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        financePanel,
                        const SizedBox(height: 16),
                        accountPanel,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.bloodRed,
                    side: BorderSide(
                      color: AppTheme.bloodRed.withOpacity(0.55),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Выйти из аккаунта'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.voidBlack,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Экспорт данных',
                  style: TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Выберите набор для выгрузки в CSV.',
                  style: TextStyle(color: AppTheme.mistGray),
                ),
                const SizedBox(height: 18),
                _ExportOption(
                  icon: Icons.folder_outlined,
                  label: 'Проекты',
                  onTap: () => _export(sheetContext, ref, 'projects'),
                ),
                _ExportOption(
                  icon: Icons.task_outlined,
                  label: 'Задачи',
                  onTap: () => _export(sheetContext, ref, 'tasks'),
                ),
                _ExportOption(
                  icon: Icons.receipt_long_outlined,
                  label: 'Транзакции',
                  onTap: () => _export(sheetContext, ref, 'transactions'),
                ),
                _ExportOption(
                  icon: Icons.archive_outlined,
                  label: 'Все данные',
                  onTap: () => _export(sheetContext, ref, 'all'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    try {
      late final result;
      if (type == 'projects') {
        result = await ExportService.exportProjectsToCSV(
          ref.read(projectsProvider).projects,
        );
      } else if (type == 'tasks') {
        result = await ExportService.exportTasksToCSV(
          ref.read(tasksProvider).tasks,
        );
      } else if (type == 'transactions') {
        result = await ExportService.exportTransactionsToCSV(
          ref.read(transactionsProvider).transactions,
        );
      } else {
        result = await ExportService.exportAllDataToCSV(
          projects: ref.read(projectsProvider).projects,
          tasks: ref.read(tasksProvider).tasks,
          transactions: ref.read(transactionsProvider).transactions,
        );
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: ' + error.toString()),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return _GothicPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(user: user),
                    const SizedBox(height: 18),
                    _IdentityText(user: user),
                  ],
                )
              : Row(
                  children: [
                    _Avatar(user: user),
                    const SizedBox(width: 24),
                    Expanded(child: _IdentityText(user: user)),
                  ],
                );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Статистика'),
                onPressed: () => Navigator.pushNamed(context, '/my_stats'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.favorite_border, size: 18),
                label: const Text('Избранное'),
                onPressed: () => Navigator.pushNamed(context, '/favorites'),
              ),
              if (user.userRole == 'admin')
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                  ),
                  label: const Text('Админ-панель'),
                  onPressed: () => Navigator.pushNamed(context, '/admin_panel'),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 22),
                const Divider(),
                const SizedBox(height: 16),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 112,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.deepBlack,
        border: Border.all(color: AppTheme.goldenrod),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dimGray),
        ),
        clipBehavior: Clip.antiAlias,
        child: user.avatarUrl == null
            ? const Icon(
                Icons.person_outline,
                color: AppTheme.ashGray,
                size: 44,
              )
            : Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_outline,
                  color: AppTheme.ashGray,
                  size: 44,
                ),
              ),
      ),
    );
  }
}

class _IdentityText extends StatelessWidget {
  const _IdentityText({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName ?? user.email.split('@').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.verified_outlined,
                color: AppTheme.electricBlue,
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          user.email,
          style: const TextStyle(color: AppTheme.ashGray, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppTheme.gothicBadge(
              _roleLabel(user.userRole),
              color: _roleColor(user.userRole),
            ),
            if (user.reviewsCount > 0)
              AppTheme.gothicBadge(
                (user.averageRating?.toStringAsFixed(1) ?? '0') +
                    ' / ' +
                    user.reviewsCount.toString() +
                    ' отзывов',
                color: AppTheme.goldenrod,
              ),
          ],
        ),
      ],
    );
  }
}

class _FinancePanel extends StatelessWidget {
  const _FinancePanel({
    required this.loading,
    required this.balance,
    required this.earned,
    required this.spent,
  });

  final bool loading;
  final double? balance;
  final double? earned;
  final double? spent;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return _GothicPanel(
      title: 'ФИНАНСОВАЯ СВОДКА',
      accent: AppTheme.goldenrod,
      child: loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: [
                _DataRow(
                  label: 'Доступный баланс',
                  value: currency.format(balance ?? 0),
                  valueColor: AppTheme.ghostWhite,
                ),
                const Divider(height: 25),
                _DataRow(
                  label: 'Заработано',
                  value: currency.format(earned ?? 0),
                  valueColor: AppTheme.gothicGreen,
                ),
                const SizedBox(height: 14),
                _DataRow(
                  label: 'Потрачено',
                  value: currency.format(spent ?? 0),
                  valueColor: AppTheme.bloodRed,
                ),
              ],
            ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return _GothicPanel(
      title: 'УЧЁТНАЯ ЗАПИСЬ',
      accent: AppTheme.deepPurple,
      child: Column(
        children: [
          _DataRow(
            label: 'Статус',
            value: user.isActive ? 'Активен' : 'Неактивен',
            valueColor:
                user.isActive ? AppTheme.gothicGreen : AppTheme.bloodRed,
          ),
          if (user.createdAt != null) ...[
            const SizedBox(height: 14),
            _DataRow(
              label: 'Дата регистрации',
              value: DateFormat('dd.MM.yyyy').format(user.createdAt!),
            ),
          ],
          if (user.lastLogin != null) ...[
            const SizedBox(height: 14),
            _DataRow(
              label: 'Последний вход',
              value: DateFormat('dd.MM.yyyy HH:mm').format(user.lastLogin!),
            ),
          ],
          const Divider(height: 25),
          const _DataRow(
            label: 'Пространство',
            value: 'Creative Collective',
            valueColor: AppTheme.goldenrod,
          ),
        ],
      ),
    );
  }
}

class _GothicPanel extends StatelessWidget {
  const _GothicPanel({
    required this.child,
    this.title,
    this.accent = AppTheme.subtleAccent,
  });

  final Widget child;
  final String? title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack,
        border: Border.all(color: AppTheme.dimGray),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -22,
            top: -22,
            child: Container(width: 2, height: 42, color: accent),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 18),
              ],
              child,
            ],
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor = AppTheme.ashGray,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.mistGray, fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.goldenrod),
      title: Text(label),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.mistGray,
      ),
      onTap: onTap,
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'client':
      return 'Заказчик';
    case 'freelancer':
      return 'Фрилансер';
    case 'admin':
      return 'Администратор';
    case 'manager':
      return 'Менеджер';
    default:
      return 'Участник';
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'client':
      return AppTheme.electricBlue;
    case 'freelancer':
      return AppTheme.gothicGreen;
    case 'admin':
      return AppTheme.bloodRed;
    default:
      return AppTheme.ashGray;
  }
}
