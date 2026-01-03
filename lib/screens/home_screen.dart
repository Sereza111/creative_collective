import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/projects_provider.dart';
import 'dashboard_screen.dart';

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
    final activeProjects = ref.watch(activeProjectsProvider);
    final activeTasks = tasksState.tasks.where((t) => 
      t.status == 'todo' || t.status == 'in_progress'
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ГЛАВНАЯ'),
        actions: [
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
                      authState.user?.username ?? 'Пользователь',
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
            AppTheme.slideUpAnimation(
              child: _buildStatCard(
                context,
                'Активные задачи',
                    '$activeTasks',
                Icons.circle_outlined,
              ),
            ),
            const SizedBox(height: 20),
            AppTheme.slideUpAnimation(
              duration: const Duration(milliseconds: 900),
              child: _buildStatCard(
                context,
                    'Проекты',
                    '${activeProjects.length}',
                    Icons.change_history_outlined,
              ),
            ),
            const SizedBox(height: 20),
            AppTheme.slideUpAnimation(
              duration: const Duration(milliseconds: 1000),
              child: _buildStatCard(
                context,
                    'Всего задач',
                    '${tasksState.tasks.length}',
                    Icons.square_outlined,
              ),
            ),
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
