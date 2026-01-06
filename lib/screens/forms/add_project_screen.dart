import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/projects_provider.dart';
import 'package:intl/intl.dart';

class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _selectedStatus = 'planning';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      initialDate: _selectedEndDate ?? (_selectedStartDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите дату начала'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
        return;
      }

      if (_selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите дату окончания'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
        
        await ref.read(projectsProvider.notifier).createProject({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _selectedStatus,
          'start_date': _selectedStartDate!.toIso8601String(),
          'end_date': _selectedEndDate!.toIso8601String(),
          'budget': budget,
          'progress': 0,
          'spent': 0,
        });

        // Reload projects list
        await ref.read(projectsProvider.notifier).loadProjects();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект успешно создан'),
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
          'НОВЫЙ ПРОЕКТ',
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
              // Name field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.tombstoneWhite),
                decoration: InputDecoration(
                  labelText: 'НАЗВАНИЕ ПРОЕКТА',
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
                    return 'Введите название проекта';
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
                  DropdownMenuItem(value: 'planning', child: Text('Планирование')),
                  DropdownMenuItem(value: 'active', child: Text('Активен')),
                  DropdownMenuItem(value: 'on_hold', child: Text('Приостановлен')),
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

              // Budget field
              TextFormField(
                controller: _budgetController,
                style: TextStyle(color: AppTheme.tombstoneWhite),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'БЮДЖЕТ (₽)',
                  labelStyle: TextStyle(
                    color: AppTheme.mistGray,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.mistGray),
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
                    return 'Введите бюджет';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Start date picker
              GestureDetector(
                onTap: _selectStartDate,
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
                              'ДАТА НАЧАЛА',
                              style: TextStyle(
                                color: AppTheme.mistGray,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedStartDate != null
                                  ? dateFormat.format(_selectedStartDate!)
                                  : 'Выберите дату',
                              style: TextStyle(
                                color: _selectedStartDate != null
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

              const SizedBox(height: 20),

              // End date picker
              GestureDetector(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dimGray),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: AppTheme.mistGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ДАТА ОКОНЧАНИЯ',
                              style: TextStyle(
                                color: AppTheme.mistGray,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEndDate != null
                                  ? dateFormat.format(_selectedEndDate!)
                                  : 'Выберите дату',
                              style: TextStyle(
                                color: _selectedEndDate != null
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
                          'СОЗДАТЬ ПРОЕКТ',
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

