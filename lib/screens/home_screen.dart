import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/notifications_provider.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on init
    Future.microtask(() {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(projectsProvider.notifier).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tasksState = ref.watch(tasksProvider);
    final projectsState = ref.watch(projectsProvider);
    final activeProjects = ref.watch(activeProjectsProvider) ?? [];
    final activeTasks = (tasksState.tasks ?? []).where((t) => 
      t.status == 'todo' || t.status == 'in_progress'
    ).length;

    final notificationsState = ref.watch(notificationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ГЛАВНАЯ'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                tooltip: 'Уведомления',
              ),
              if (notificationsState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.bloodRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notificationsState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Выход',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tasksProvider.notifier).loadTasks();
          await ref.read(projectsProvider.notifier).loadProjects();
        },
        backgroundColor: AppTheme.shadowGray,
        color: AppTheme.tombstoneWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.fadeInAnimation(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    AppTheme.gothicTitle(
                      authState.user?.fullName ?? authState.user?.email.split('@')[0] ?? 'Пользователь',
                    ),
                  const SizedBox(height: 16),
                  Text(
                      authState.user?.role == 'admin' 
                          ? 'АДМИНИСТРАТОР' 
                          : 'Creative Collective',
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
              if (tasksState.isLoading || projectsState.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.tombstoneWhite,
                      ),
                    ),
                  ),
                )
              else ...[
                // Overview Cards
                AppTheme.fadeInAnimation(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'АКТИВНЫЕ ПРОЕКТЫ',
                          activeProjects.length.toString(),
                          Icons.folder_open,
                          AppTheme.tombstoneWhite,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'АКТИВНЫЕ ЗАДАЧИ',
                          activeTasks.toString(),
                          Icons.assignment,
                          AppTheme.tombstoneWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.fadeInAnimation(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'ВСЕГО ПРОЕКТОВ',
                          projectsState.projects.length.toString(),
                          Icons.folder,
                          AppTheme.mistGray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'ВСЕГО ЗАДАЧ',
                          (tasksState.tasks ?? []).length.toString(),
                          Icons.assignment_turned_in,
                          AppTheme.mistGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Recent Activity Section
                AppTheme.gothicTitle('НЕДАВНИЕ ПРОЕКТЫ'),
                const SizedBox(height: 24),
                if (activeProjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        'Нет активных проектов',
                        style: TextStyle(
                          color: AppTheme.mistGray,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...activeProjects.take(3).map((project) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppTheme.animatedGothicCard(
                        child: ListTile(
                          leading: Icon(Icons.folder, color: AppTheme.tombstoneWhite),
                          title: Text(
                            project.name.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.tombstoneWhite,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          subtitle: Text(
                            '${project.progress}% завершено',
                            style: TextStyle(
                              color: AppTheme.mistGray,
                              fontSize: 10,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward, color: AppTheme.mistGray),
                          onTap: () {
                            // Navigate to project details
                          },
                        ),
                      ),
                    );
                  }).toList(),
              ],
            
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
                      text: 'Обновить данные',
                      onPressed: () async {
                        await ref.read(tasksProvider.notifier).loadTasks();
                        await ref.read(projectsProvider.notifier).loadProjects();
                        if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                              content: Text('Данные обновлены'),
                          backgroundColor: AppTheme.shadowGray,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                        }
                    },
                    isPrimary: false,
                  ),
                ],
              ),
            ),

              // Error messages
              if (tasksState.error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.bloodRed),
                    color: AppTheme.bloodRed.withOpacity(0.1),
                  ),
                  child: Text(
                    'Ошибка загрузки задач: ${tasksState.error}',
                    style: TextStyle(color: AppTheme.bloodRed, fontSize: 12),
                  ),
                ),
              ],
              if (projectsState.error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.bloodRed),
                    color: AppTheme.bloodRed.withOpacity(0.1),
                  ),
                  child: Text(
                    'Ошибка загрузки проектов: ${projectsState.error}',
                    style: TextStyle(color: AppTheme.bloodRed, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
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
                  color: iconColor.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}
