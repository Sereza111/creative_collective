import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/tasks_provider.dart';
import 'forms/add_task_screen.dart';
import 'task_detail_screen.dart';
import 'package:intl/intl.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    Future.microtask(() {
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'todo':
        return 'Ожидает';
      case 'in_progress':
        return 'В работе';
      case 'review':
        return 'На проверке';
      case 'done':
        return 'Завершено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    
    // Filter tasks based on selected filter and search query
    var filteredTasks = _selectedFilter == 'all'
        ? tasksState.tasks
        : tasksState.tasks.where((task) => task.status == _selectedFilter).toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery) ||
               (task.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ЗАДАЧИ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tasksProvider.notifier).loadTasks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppTheme.gothicTextField(
              controller: _searchController,
              hintText: 'Поиск задач...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Все'),
                const SizedBox(width: 10),
                _buildFilterChip('todo', 'Ожидает'),
                const SizedBox(width: 10),
                _buildFilterChip('in_progress', 'В работе'),
                const SizedBox(width: 10),
                _buildFilterChip('done', 'Завершено'),
              ],
            ),
          ),
          
          Expanded(
            child: tasksState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.tombstoneWhite,
                      ),
                    ),
                  )
                : tasksState.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.bloodRed,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Ошибка загрузки задач',
                                style: TextStyle(
                                  color: AppTheme.tombstoneWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tasksState.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.mistGray,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppTheme.gothicButton(
                                text: 'Повторить',
                                onPressed: () {
                                  ref.read(tasksProvider.notifier).loadTasks();
                                },
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredTasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: AppTheme.mistGray,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Нет задач',
                                    style: TextStyle(
                                      color: AppTheme.tombstoneWhite,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _selectedFilter == 'all'
                                        ? 'Создайте первую задачу'
                                        : 'Нет задач с выбранным статусом',
                                    style: TextStyle(
                                      color: AppTheme.mistGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(tasksProvider.notifier).loadTasks();
                            },
                            backgroundColor: AppTheme.shadowGray,
                            color: AppTheme.tombstoneWhite,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: AppTheme.slideUpAnimation(
                                    offset: 15,
                                    duration: Duration(
                                      milliseconds: 800 + (index * 100),
                                    ),
                                    child: _buildTaskCard(context, task),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.tombstoneWhite : AppTheme.shadowGray,
          border: Border.all(
            color: isSelected ? AppTheme.tombstoneWhite : AppTheme.dimGray,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.voidBlack : AppTheme.mistGray,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, task) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(task: task),
          ),
        );
      },
      child: AppTheme.animatedGothicCard(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.tombstoneWhite,
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppTheme.gothicBadge(_getStatusText(task.status)),
              ],
            ),
            
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mistGray,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Дедлайн', dateFormat.format(task.dueDate)),
                _buildInfoItem('Приоритет', task.priority.toString()),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: AppTheme.mistGray,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: AppTheme.ashGray,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
