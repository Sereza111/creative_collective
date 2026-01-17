import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/pie_chart_widget.dart';

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
      ref.read(balanceProvider.notifier).loadBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final tasksState = ref.watch(tasksProvider);
    final financeAsync = ref.watch(balanceProvider);
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
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(projectsProvider.notifier).loadProjects();
              await ref.read(tasksProvider.notifier).loadTasks();
              await ref.read(balanceProvider.notifier).loadBalance();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectsProvider.notifier).loadProjects();
          await ref.read(tasksProvider.notifier).loadTasks();
          await ref.read(balanceProvider.notifier).loadBalance();
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
                child: AppTheme.gothicTitle('АНАЛИТИКА'),
              ),
              const SizedBox(height: 32),
              AppTheme.gothicDivider(),
              const SizedBox(height: 32),
              
              // Overview Stats - Quick Actions
              _buildQuickStats(projectsState, tasksState, financeAsync),
              
              const SizedBox(height: 32),
              
              // Charts Row
              if (!projectsState.isLoading && projectsState.projects.isNotEmpty)
                _buildChartsRow(projectsState, tasksState),
              
              const SizedBox(height: 32),
              
              // Budget Overview with Circular Progress
              if (!projectsState.isLoading && projectsState.projects.isNotEmpty)
                _buildBudgetCircular(projectsState),
              
              const SizedBox(height: 32),
              
              // Activity Overview
              _buildActivityOverview(projectsState, tasksState),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(projectsState, tasksState, financeAsync) {
    final activeProjects = projectsState.projects.where((p) => p.status == 'active').length;
    final activeTasks = tasksState.tasks.where((t) => t.status == 'in_progress').length;
    final completedToday = tasksState.tasks.where((t) => 
      t.status == 'done' && 
      t.updatedAt != null &&
      DateTime.now().difference(t.updatedAt!).inHours < 24
    ).length;

    return AppTheme.fadeInAnimation(
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'АКТИВНЫХ\nПРОЕКТОВ',
              '$activeProjects',
              Icons.rocket_launch,
              AppTheme.gothicBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'ЗАДАЧ\nВ РАБОТЕ',
              '$activeTasks',
              Icons.trending_up,
              AppTheme.gothicGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'ЗАВЕРШЕНО\nСЕГОДНЯ',
              '$completedToday',
              Icons.check_circle_outline,
              AppTheme.electricBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AppTheme.animatedGothicCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w200,
                color: color,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: AppTheme.mistGray,
                letterSpacing: 1.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow(projectsState, tasksState) {
    // Calculate project statuses
    final projectStatuses = <String, int>{
      'Планирование': 0,
      'Активные': 0,
      'Завершённые': 0,
      'На паузе': 0,
    };
    
    for (var project in projectsState.projects) {
      switch (project.status) {
        case 'planning':
          projectStatuses['Планирование'] = projectStatuses['Планирование']! + 1;
          break;
        case 'active':
          projectStatuses['Активные'] = projectStatuses['Активные']! + 1;
          break;
        case 'completed':
          projectStatuses['Завершённые'] = projectStatuses['Завершённые']! + 1;
          break;
        case 'on_hold':
          projectStatuses['На паузе'] = projectStatuses['На паузе']! + 1;
          break;
      }
    }

    final projectColors = {
      'Планирование': AppTheme.electricBlue,
      'Активные': AppTheme.gothicGreen,
      'Завершённые': AppTheme.shadowGray,
      'На паузе': AppTheme.goldenrod,
    };

    // Calculate task statuses
    final taskStatuses = <String, int>{
      'К выполнению': 0,
      'В работе': 0,
      'Выполнено': 0,
    };
    
    for (var task in tasksState.tasks) {
      switch (task.status) {
        case 'todo':
          taskStatuses['К выполнению'] = taskStatuses['К выполнению']! + 1;
          break;
        case 'in_progress':
          taskStatuses['В работе'] = taskStatuses['В работе']! + 1;
          break;
        case 'done':
          taskStatuses['Выполнено'] = taskStatuses['Выполнено']! + 1;
          break;
      }
    }

    final taskColors = {
      'К выполнению': AppTheme.electricBlue,
      'В работе': AppTheme.goldenrod,
      'Выполнено': AppTheme.gothicGreen,
    };

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 900),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTheme.animatedGothicCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'ПРОЕКТЫ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PieChartWidget(
                      data: projectStatuses,
                      colors: projectColors,
                      size: 160,
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
                      'ЗАДАЧИ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PieChartWidget(
                      data: taskStatuses,
                      colors: taskColors,
                      size: 160,
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

  Widget _buildBudgetCircular(projectsState) {
    double totalBudget = 0;
    double totalSpent = 0;
    
    for (var project in projectsState.projects) {
      totalBudget += project.budget;
      totalSpent += project.spent;
    }

    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 1100),
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ИСПОЛЬЗОВАНИЕ БЮДЖЕТА',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Circular Progress
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 12,
                            backgroundColor: AppTheme.dimGray.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentage > 0.8 
                                ? AppTheme.bloodRed 
                                : percentage > 0.5 
                                  ? AppTheme.goldenrod 
                                  : AppTheme.gothicGreen,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w200,
                                color: AppTheme.tombstoneWhite,
                                fontFamily: 'serif',
                              ),
                            ),
                            Text(
                              'ПОТРАЧЕНО',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.mistGray,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Budget Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBudgetRow(
                        'Общий бюджет:',
                        currencyFormat.format(totalBudget),
                        AppTheme.tombstoneWhite,
                      ),
                      const SizedBox(height: 16),
                      _buildBudgetRow(
                        'Потрачено:',
                        currencyFormat.format(totalSpent),
                        percentage > 0.8 ? AppTheme.bloodRed : AppTheme.goldenrod,
                      ),
                      const SizedBox(height: 16),
                      _buildBudgetRow(
                        'Осталось:',
                        currencyFormat.format(totalBudget - totalSpent),
                        AppTheme.gothicGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.mistGray,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOverview(projectsState, tasksState) {
    final recentProjects = projectsState.projects.take(3).toList();
    final recentTasks = tasksState.tasks.where((t) => t.status != 'done').take(5).toList();

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 1300),
      child: AppTheme.animatedGothicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'НЕДАВНЯЯ АКТИВНОСТЬ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mistGray,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.timeline, color: AppTheme.electricBlue, size: 20),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Projects
              if (recentProjects.isNotEmpty) ...[
                Text(
                  'Текущие проекты:',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.ashGray,
                  ),
                ),
                const SizedBox(height: 12),
                ...recentProjects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(project.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.tombstoneWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
              ],
              
              // Recent Tasks
              if (recentTasks.isNotEmpty) ...[
                Text(
                  'Ближайшие задачи:',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.ashGray,
                  ),
                ),
                const SizedBox(height: 12),
                ...recentTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        task.status == 'in_progress' 
                          ? Icons.play_circle_outline 
                          : Icons.circle_outlined,
                        color: _getStatusColor(task.status),
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.ashGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planning':
      case 'todo':
        return AppTheme.electricBlue;
      case 'active':
      case 'in_progress':
        return AppTheme.goldenrod;
      case 'completed':
      case 'done':
        return AppTheme.gothicGreen;
      case 'on_hold':
        return AppTheme.shadowGray;
      default:
        return AppTheme.mistGray;
    }
  }
}
