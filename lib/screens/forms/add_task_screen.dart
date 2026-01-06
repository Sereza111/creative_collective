import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/projects_provider.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedProjectId;
  String _selectedStatus = 'todo';
  int _selectedPriority = 3;
  DateTime? _selectedDueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load projects if not already loaded
    Future.microtask(() {
      if (ref.read(projectsProvider).projects.isEmpty) {
        ref.read(projectsProvider.notifier).loadProjects();
      }
    });
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
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите проект'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
        return;
      }

      if (_selectedDueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите дату дедлайна'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(tasksProvider.notifier).createTask({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _selectedStatus,
          'priority': _selectedPriority,
          'project_id': _selectedProjectId,
          'due_date': _selectedDueDate!.toIso8601String(),
        });

        // Reload tasks list
        await ref.read(tasksProvider.notifier).loadTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Задача успешно создана'),
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
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.tombstoneWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'НОВАЯ ЗАДАЧА',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppTheme.tombstoneWhite),
                decoration: InputDecoration(
                  labelText: 'НАЗВАНИЕ ЗАДАЧИ',
                  labelStyle: TextStyle(
                    color: AppTheme.mistGray,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(Icons.title, color: AppTheme.mistGray),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.bloodRed),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.bloodRed, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название задачи';
                  }
                  if (value.length < 3) {
                    return 'Минимум 3 символа';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description field
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: AppTheme.tombstoneWhite),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'ОПИСАНИЕ',
                  labelStyle: TextStyle(
                    color: AppTheme.mistGray,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description, color: AppTheme.mistGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Project selector
              if (projectsState.isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dimGray),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mistGray),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Загрузка проектов...',
                        style: TextStyle(color: AppTheme.mistGray),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: InputDecoration(
                    labelText: 'ПРОЕКТ',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.folder, color: AppTheme.mistGray),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  dropdownColor: AppTheme.shadowGray,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  items: projectsState.projects.map((project) {
                    return DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                ),

              const SizedBox(height: 20),

              // Status selector
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'СТАТУС',
                  labelStyle: TextStyle(
                    color: AppTheme.mistGray,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(Icons.flag, color: AppTheme.mistGray),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                dropdownColor: AppTheme.shadowGray,
                style: TextStyle(color: AppTheme.tombstoneWhite),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('Ожидает')),
                  DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
                  DropdownMenuItem(value: 'review', child: Text('На проверке')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Priority selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ПРИОРИТЕТ: $_selectedPriority',
                    style: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dimGray),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        final priority = index + 1;
                        final isSelected = _selectedPriority == priority;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.tombstoneWhite : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppTheme.tombstoneWhite : AppTheme.dimGray,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$priority',
                                style: TextStyle(
                                  color: isSelected ? AppTheme.voidBlack : AppTheme.mistGray,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Due date picker
              GestureDetector(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dimGray),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.mistGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ДЕДЛАЙН',
                              style: TextStyle(
                                color: AppTheme.mistGray,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDueDate != null
                                  ? dateFormat.format(_selectedDueDate!)
                                  : 'Выберите дату',
                              style: TextStyle(
                                color: _selectedDueDate != null
                                    ? AppTheme.tombstoneWhite
                                    : AppTheme.mistGray,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: AppTheme.mistGray, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tombstoneWhite,
                    foregroundColor: AppTheme.voidBlack,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.voidBlack),
                          ),
                        )
                      : Text(
                          'СОЗДАТЬ ЗАДАЧУ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
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
}

