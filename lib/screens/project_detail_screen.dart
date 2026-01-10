import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late TextEditingController _progressController;
  late String _selectedStatus;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _budgetController = TextEditingController(text: widget.project.budget.toStringAsFixed(0));
    _progressController = TextEditingController(text: widget.project.progress.toString());
    _selectedStatus = widget.project.status;
    _selectedStartDate = widget.project.startDate;
    _selectedEndDate = widget.project.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
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
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
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
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEditing = true;
    });

    try {
      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'start_date': _selectedStartDate.toIso8601String(),
        'end_date': _selectedEndDate.toIso8601String(),
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
        'progress': int.tryParse(_progressController.text.trim()) ?? 0,
      };

      await ref.read(projectsProvider.notifier).updateProject(widget.project.id, projectData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект обновлён'),
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

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.shadowGray,
        title: const Text(
          'Удалить проект?',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        content: const Text(
          'Это действие нельзя отменить. Все задачи проекта будут удалены.',
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
      await ref.read(projectsProvider.notifier).deleteProject(widget.project.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект удалён'),
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
    final budgetFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        title: Text(
          'ДЕТАЛИ ПРОЕКТА',
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
              onPressed: _deleteProject,
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
                // Название проекта
                Text(
                  'НАЗВАНИЕ ПРОЕКТА',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicTextField(
                  controller: _nameController,
                  hintText: 'Введите название',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название проекта';
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
                  hintText: 'Описание проекта',
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
                AppTheme.gothicDropdown<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'planning', child: Text('Планирование')),
                    DropdownMenuItem(value: 'active', child: Text('Активный')),
                    DropdownMenuItem(value: 'on_hold', child: Text('Приостановлен')),
                    DropdownMenuItem(value: 'completed', child: Text('Завершён')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Отменён')),
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

                // Бюджет
                Text(
                  'БЮДЖЕТ (₽)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicTextField(
                  controller: _budgetController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.attach_money, size: 20),
                ),
                const SizedBox(height: 24),

                // Прогресс
                Text(
                  'ПРОГРЕСС (%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                AppTheme.gothicTextField(
                  controller: _progressController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final progress = int.tryParse(value ?? '');
                    if (progress != null && (progress < 0 || progress > 100)) {
                      return 'Прогресс должен быть от 0 до 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Дата начала
                Text(
                  'ДАТА НАЧАЛА',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectStartDate,
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
                          dateFormat.format(_selectedStartDate),
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

                // Дата окончания
                Text(
                  'ДАТА ОКОНЧАНИЯ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectEndDate,
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
                          dateFormat.format(_selectedEndDate),
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

                // Статистика
                AppTheme.animatedGothicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'СТАТИСТИКА',
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
                              'Бюджет:',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              budgetFormat.format(widget.project.budget),
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
                              'Потрачено:',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              budgetFormat.format(widget.project.spent),
                              style: TextStyle(
                                color: AppTheme.bloodRed,
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
                              'Прогресс:',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${widget.project.progress}%',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Кнопка сохранения
                AppTheme.gothicButton(
                  text: _isEditing ? 'СОХРАНЕНИЕ...' : 'СОХРАНИТЬ ИЗМЕНЕНИЯ',
                  onPressed: _isEditing ? null : _saveProject,
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

