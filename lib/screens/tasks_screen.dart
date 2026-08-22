import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workspace_components.dart';
import 'forms/add_task_screen.dart';
import 'task_detail_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tasksProvider.notifier).loadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (mounted) {
      await ref.read(tasksProvider.notifier).loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final filteredTasks = state.tasks.where((task) {
      final matchesStatus =
          _selectedFilter == 'all' || task.status == _selectedFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          IconButton(
            tooltip: 'Обновить задачи',
            onPressed: () => ref.read(tasksProvider.notifier).loadTasks(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Создать задачу',
            onPressed: _openCreateTask,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: WorkspaceContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspacePageIntro(
              eyebrow: 'Контроль исполнения',
              title: 'Задачи без лишнего шума',
              description:
                  'Сроки, приоритеты и ответственные в одном рабочем списке.',
              actions: [
                ElevatedButton.icon(
                  onPressed: _openCreateTask,
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Новая задача'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            WorkspaceSearchField(
              controller: _searchController,
              hintText: 'Найти задачу по названию или описанию',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(state, 'all', 'Все'),
                _filterChip(state, 'todo', 'Ожидают'),
                _filterChip(state, 'in_progress', 'В работе'),
                _filterChip(state, 'done', 'Завершены'),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildContent(state, filteredTasks)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(TasksState state, String value, String label) {
    final count = value == 'all'
        ? state.tasks.length
        : state.tasks.where((task) => task.status == value).length;
    return WorkspaceFilterChip(
      label: label,
      count: count,
      selected: _selectedFilter == value,
      onTap: () => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildContent(TasksState state, List<Task> tasks) {
    if (state.isLoading && state.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.tasks.isEmpty) {
      return WorkspaceErrorState(
        message: state.error!,
        onRetry: () => ref.read(tasksProvider.notifier).loadTasks(),
      );
    }
    if (tasks.isEmpty) {
      final isSearching = _searchQuery.trim().isNotEmpty;
      return WorkspaceEmptyState(
        icon: isSearching ? Icons.search_off : Icons.task_alt,
        title: isSearching ? 'Ничего не найдено' : 'Задач пока нет',
        message: isSearching
            ? 'Измените запрос или сбросьте фильтр.'
            : _selectedFilter == 'all'
                ? 'Создайте первую задачу и зафиксируйте ответственного и срок.'
                : 'В этой группе задач пока нет.',
        action: _selectedFilter == 'all' && !isSearching
            ? ElevatedButton.icon(
                onPressed: _openCreateTask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Создать задачу'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      color: AppTheme.goldenrod,
      backgroundColor: AppTheme.shadowGray,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 620,
          mainAxisExtent: 204,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: tasks.length,
        itemBuilder: (_, index) => _TaskCard(task: tasks[index]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  String get _statusLabel => switch (task.status) {
        'todo' => 'Ожидает',
        'in_progress' => 'В работе',
        'review' => 'На проверке',
        'done' => 'Завершено',
        'cancelled' => 'Отменено',
        _ => task.status,
      };

  Color get _statusColor => switch (task.status) {
        'in_progress' => AppTheme.electricBlue,
        'review' => AppTheme.goldenrod,
        'done' => AppTheme.gothicGreen,
        'cancelled' => AppTheme.bloodRed,
        _ => AppTheme.ashGray,
      };

  String get _priorityLabel => switch (task.priority) {
        1 => 'Низкий',
        2 => 'Обычный',
        3 => 'Средний',
        4 => 'Высокий',
        5 => 'Критический',
        _ => task.priority.toString(),
      };

  @override
  Widget build(BuildContext context) {
    final dueDate = DateFormat('dd.MM.yyyy').format(task.dueDate);
    final overdue =
        task.status != 'done' && task.dueDate.isBefore(DateTime.now());

    return WorkspacePanel(
      accent: _statusColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontFamily: 'Georgia',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.description.isEmpty
                ? 'Описание не добавлено'
                : task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: task.description.isEmpty
                  ? AppTheme.mistGray.withOpacity(0.65)
                  : AppTheme.ashGray,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetaItem(
                icon: Icons.event_outlined,
                label: overdue ? 'Просрочено: $dueDate' : dueDate,
                color: overdue ? AppTheme.bloodRed : AppTheme.ashGray,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _MetaItem(
                  icon: Icons.person_outline,
                  label: task.assignedFullName?.trim().isNotEmpty == true
                      ? task.assignedFullName!
                      : 'Не назначен',
                ),
              ),
              _MetaItem(
                icon: Icons.flag_outlined,
                label: _priorityLabel,
                color: task.priority >= 4
                    ? AppTheme.subtleAccent
                    : AppTheme.mistGray,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        border: Border.all(color: color.withOpacity(0.75)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppTheme.mistGray;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: itemColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: itemColor, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
