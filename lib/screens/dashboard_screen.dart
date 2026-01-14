import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/finance_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data
    Future.microtask(() {
      ref.read(projectsProvider.notifier).loadProjects();
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(financeProvider.notifier).loadFinance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final tasksState = ref.watch(tasksProvider);
    final financeAsync = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавить проект'),
                  backgroundColor: AppTheme.shadowGray,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectsProvider.notifier).loadProjects();
          await ref.read(tasksProvider.notifier).loadTasks();
          await ref.read(financeProvider.notifier).loadFinance();
        },
        backgroundColor: AppTheme.shadowGray,
        color: AppTheme.tombstoneWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppTheme.fadeInAnimation(
                child: AppTheme.gothicTitle('DASHBOARD'),
              ),
              const SizedBox(height: 32),
              AppTheme.gothicDivider(),
              const SizedBox(height: 32),
              
              // Overview Stats
              _buildOverviewStats(projectsState, tasksState, financeAsync),
              
              const SizedBox(height: 32),
              
              // Projects by Status Chart
              if (!projectsState.isLoading && projectsState.projects.isNotEmpty)
                _buildProjectsChart(projectsState),
              
              const SizedBox(height: 32),
              
              // Tasks by Status Chart  
              if (!tasksState.isLoading && tasksState.tasks.isNotEmpty)
                _buildTasksChart(tasksState),
              
              const SizedBox(height: 32),
              
              // Budget Overview
              if (!projectsState.isLoading && projectsState.projects.isNotEmpty)
                _buildBudgetOverview(projectsState),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStats(projectsState, tasksState, financeAsync) {
    return AppTheme.fadeInAnimation(
      child: Row(
        children: [
          Expanded(
            child: AppTheme.animatedGothicCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${projectsState.projects.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.tombstoneWhite,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ПРОЕКТОВ',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppTheme.animatedGothicCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${tasksState.tasks.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.tombstoneWhite,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ЗАДАЧ',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsChart(projectsState) {
    final statuses = {'planning': 0, 'active': 0, 'completed': 0, 'on_hold': 0};
    for (var project in projectsState.projects) {
      statuses[project.status] = (statuses[project.status] ?? 0) + 1;
    }

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 900),
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ПРОЕКТЫ ПО СТАТУСАМ',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusBar('Планирование', statuses['planning']!, Colors.blue),
              const SizedBox(height: 12),
              _buildStatusBar('Активные', statuses['active']!, Colors.green),
              const SizedBox(height: 12),
              _buildStatusBar('Завершённые', statuses['completed']!, Colors.grey),
              const SizedBox(height: 12),
              _buildStatusBar('На паузе', statuses['on_hold']!, Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksChart(tasksState) {
    final statuses = {'todo': 0, 'in_progress': 0, 'done': 0};
    for (var task in tasksState.tasks) {
      statuses[task.status] = (statuses[task.status] ?? 0) + 1;
    }

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 1100),
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ЗАДАЧИ ПО СТАТУСАМ',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusBar('К выполнению', statuses['todo']!, Colors.blue),
              const SizedBox(height: 12),
              _buildStatusBar('В работе', statuses['in_progress']!, Colors.orange),
              const SizedBox(height: 12),
              _buildStatusBar('Выполнено', statuses['done']!, Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(projectsState) {
    double totalBudget = 0;
    double totalSpent = 0;
    
    for (var project in projectsState.projects) {
      totalBudget += project.budget;
      totalSpent += project.spent;
    }

    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 1300),
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'БЮДЖЕТ',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Всего',
                        style: TextStyle(fontSize: 10, color: AppTheme.mistGray),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalBudget),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                          color: AppTheme.tombstoneWhite,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Потрачено',
                        style: TextStyle(fontSize: 10, color: AppTheme.mistGray),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(totalSpent),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                          color: AppTheme.bloodRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dimGray.withOpacity(0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bloodRed,
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

  Widget _buildStatusBar(String label, int count, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.ashGray,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.dimGray.withOpacity(0.2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: count > 0 ? (count / 10).clamp(0.1, 1.0) : 0.1,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
