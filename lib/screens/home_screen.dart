import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'forms/add_project_screen.dart';
import 'forms/add_task_screen.dart';
import 'notifications_screen.dart';
import 'project_detail_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(tasksProvider.notifier).loadTasks(),
      ref.read(projectsProvider.notifier).loadProjects(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final taskState = ref.watch(tasksProvider);
    final projectState = ref.watch(projectsProvider);
    final notifications = ref.watch(notificationsProvider);
    final activeProjects = projectState.projects
        .where((project) => project.status == 'active')
        .toList();
    final activeTasks = taskState.tasks
        .where((task) => task.status == 'todo' || task.status == 'in_progress')
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completedTasks =
        taskState.tasks.where((task) => task.status == 'done').length;
    final dueSoon = activeTasks
        .where(
          (task) => task.dueDate.isBefore(
            DateTime.now().add(const Duration(days: 7)),
          ),
        )
        .length;
    final name = auth.user?.fullName ??
        auth.user?.email.split('@').first ??
        'Пользователь';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          _NotificationButton(
            count: notifications.unreadCount,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Выйти',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pagePadding = constraints.maxWidth < 700 ? 16.0 : 28.0;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        name: name,
                        role: auth.user?.role,
                        onAddProject: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProjectScreen(),
                          ),
                        ),
                        onAddTask: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTaskScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (taskState.error != null ||
                          projectState.error != null) ...[
                        _ErrorBanner(
                          message: taskState.error ?? projectState.error!,
                          onRetry: _loadData,
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (taskState.isLoading && projectState.isLoading)
                        const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _Metrics(
                          values: [
                            _MetricData(
                              'Активные проекты',
                              activeProjects.length,
                              Icons.folder_copy_outlined,
                              AppTheme.electricBlue,
                            ),
                            _MetricData(
                              'Задачи в работе',
                              activeTasks.length,
                              Icons.check_circle_outline,
                              AppTheme.subtleAccent,
                            ),
                            _MetricData(
                              'Срок в течение недели',
                              dueSoon,
                              Icons.schedule_outlined,
                              AppTheme.goldenrod,
                            ),
                            _MetricData(
                              'Задачи завершены',
                              completedTasks,
                              Icons.task_alt,
                              AppTheme.deepPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _WorkOverview(
                          projects: (activeProjects.isEmpty
                                  ? projectState.projects
                                  : activeProjects)
                              .take(4)
                              .toList(),
                          tasks: activeTasks.take(5).toList(),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text('Подробная аналитика'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DashboardScreen(),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.groups_outlined),
                              label: const Text('Команды и участники'),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/teams'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.role,
    required this.onAddProject,
    required this.onAddTask,
  });

  final String name;
  final String? role;
  final VoidCallback onAddProject;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 18,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'РАБОЧИЙ КАБИНЕТ',
                style: TextStyle(
                  color: AppTheme.goldenrod,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                name.toUpperCase(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Creative Collective / проекты и задачи',
                style: TextStyle(color: AppTheme.mistGray),
              ),
              const SizedBox(height: 12),
              AppTheme.gothicBadge(
                role == 'admin' ? 'Администратор' : 'Участник пространства',
                color: role == 'admin'
                    ? AppTheme.goldenrod
                    : AppTheme.subtleAccent,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('Новая задача'),
            ),
            ElevatedButton.icon(
              onPressed: onAddProject,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Новый проект'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.values});

  final List<_MetricData> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values
              .map(
                (metric) => SizedBox(
                  width: cardWidth,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack,
        border: Border.all(color: AppTheme.dimGray),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: metric.color),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    border: Border.all(color: metric.color.withOpacity(0.55)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.value.toString(),
                        style: const TextStyle(
                          color: AppTheme.ghostWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      Text(
                        metric.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.mistGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkOverview extends StatelessWidget {
  const _WorkOverview({required this.projects, required this.tasks});

  final List<Project> projects;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final projectsPanel = _Panel(
      title: 'Текущие проекты',
      subtitle: 'Прогресс и ближайшие сроки',
      icon: Icons.folder_open_outlined,
      child: projects.isEmpty
          ? const _EmptyState(
              icon: Icons.folder_outlined,
              title: 'Проектов пока нет',
              message: 'Создайте проект, чтобы собрать задачи и команду.',
            )
          : Column(
              children: projects
                  .map((project) => _ProjectRow(project: project))
                  .toList(),
            ),
    );
    final tasksPanel = _Panel(
      title: 'Ближайшие задачи',
      subtitle: 'Сначала самые срочные',
      icon: Icons.event_available_outlined,
      child: tasks.isEmpty
          ? const _EmptyState(
              icon: Icons.task_alt,
              title: 'Активных задач нет',
              message: 'Новые задачи появятся здесь по сроку выполнения.',
            )
          : Column(
              children: tasks.map((task) => _TaskRow(task: task)).toList(),
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: projectsPanel),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: tasksPanel),
            ],
          );
        }
        return Column(
          children: [
            projectsPanel,
            const SizedBox(height: 16),
            tasksPanel,
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack,
        border: Border.all(color: AppTheme.dimGray),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.subtleAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.mistGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          child,
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final progress = (project.progress / 100).clamp(0.0, 1.0);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(project: project),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AppTheme.gothicBadge(
                  _projectStatus(project.status),
                  color: _projectColor(project.status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 5),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  project.progress.toString() + '% выполнено',
                  style: const TextStyle(
                    color: AppTheme.mistGray,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'до ' + DateFormat('d MMM', 'ru_RU').format(project.endDate),
                  style: const TextStyle(
                    color: AppTheme.mistGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueDate.isBefore(DateTime.now());
    final color = overdue
        ? AppTheme.bloodRed
        : task.priority >= 4
            ? AppTheme.goldenrod
            : AppTheme.subtleAccent;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.check, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (overdue ? 'Срок истёк ' : 'До ') +
                        DateFormat('d MMM', 'ru_RU').format(task.dueDate),
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.mistGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 34, color: AppTheme.mistGray),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.tombstoneWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mistGray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bloodRed.withOpacity(0.1),
        border: Border.all(color: AppTheme.bloodRed.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.bloodRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Уведомления',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppTheme.bloodRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _projectStatus(String status) {
  switch (status) {
    case 'active':
      return 'В работе';
    case 'planning':
      return 'Планирование';
    case 'completed':
      return 'Завершён';
    case 'on_hold':
      return 'На паузе';
    default:
      return status;
  }
}

Color _projectColor(String status) {
  switch (status) {
    case 'active':
      return AppTheme.subtleAccent;
    case 'planning':
      return AppTheme.electricBlue;
    case 'completed':
      return AppTheme.deepPurple;
    case 'on_hold':
      return AppTheme.goldenrod;
    default:
      return AppTheme.mistGray;
  }
}
