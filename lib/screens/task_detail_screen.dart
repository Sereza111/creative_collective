import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../providers/projects_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedStatus;
  late int _selectedPriority;
  late DateTime _selectedDueDate;
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedStatus = widget.task.status;
    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.tombstoneWhite,
              onPrimary: AppTheme.voidBlack,
              surface: AppTheme.shadowGray,
              onSurface: AppTheme.tombstoneWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEditing = true;
    });

    try {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'priority': _selectedPriority,
        'due_date': _selectedDueDate.toIso8601String(),
      };

      await ref.read(tasksProvider.notifier).updateTask(widget.task.id, taskData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Задача обновлена'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.shadowGray,
        title: const Text(
          'Удалить задачу?',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(
            color: AppTheme.mistGray,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ОТМЕНА',
              style: TextStyle(color: AppTheme.tombstoneWhite),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'УДАЛИТЬ',
              style: TextStyle(color: AppTheme.bloodRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(tasksProvider.notifier).deleteTask(widget.task.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Задача удалена'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final projectsState = ref.watch(projectsProvider);
    final project = projectsState.projects.firstWhere(
      (p) => p.id == widget.task.projectId,
      orElse: () => projectsState.projects.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        title: Text(
          'ДЕТАЛИ ЗАДАЧИ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppTheme.tombstoneWhite,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          if (!_isEditing && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTask,
              color: AppTheme.bloodRed,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название задачи
                Text(
                  'НАЗВАНИЕ ЗАДАЧИ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicTextField(
                  controller: _titleController,
                  hintText: 'Введите название',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Описание
                Text(
                  'ОПИСАНИЕ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicTextField(
                  controller: _descriptionController,
                  hintText: 'Описание задачи',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Статус
                Text(
                  'СТАТУС',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicDropdown(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'todo', child: Text('К выполнению')),
                    DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
                    DropdownMenuItem(value: 'review', child: Text('На проверке')),
                    DropdownMenuItem(value: 'done', child: Text('Выполнено')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Приоритет
                Text(
                  'ПРИОРИТЕТ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicDropdown(
                  value: _selectedPriority,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('🔴 Высокий')),
                    DropdownMenuItem(value: 2, child: Text('🟡 Средний')),
                    DropdownMenuItem(value: 3, child: Text('🟢 Низкий')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Срок выполнения
                Text(
                  'СРОК ВЫПОЛНЕНИЯ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.shadowGray,
                      border: Border.all(color: AppTheme.dimGray),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.mistGray, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          dateFormat.format(_selectedDueDate),
                          style: TextStyle(
                            color: AppTheme.tombstoneWhite,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Информация о проекте
                AppTheme.animatedGothicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ИНФОРМАЦИЯ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.mistGray,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Проект:',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              project.name,
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Создана:',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              dateFormat.format(widget.task.createdAt),
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (widget.task.assignedTo != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Исполнитель:',
                                style: TextStyle(
                                  color: AppTheme.tombstoneWhite,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                widget.task.assignedFullName ?? 'Не назначен',
                                style: TextStyle(
                                  color: AppTheme.tombstoneWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Кнопка сохранения
                AppTheme.gothicButton(
                  text: _isEditing ? 'СОХРАНЕНИЕ...' : 'СОХРАНИТЬ ИЗМЕНЕНИЯ',
                  onPressed: _isEditing ? null : () => _saveTask(),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

