import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AddPortfolioItemScreen extends StatefulWidget {
  const AddPortfolioItemScreen({Key? key}) : super(key: key);

  @override
  State<AddPortfolioItemScreen> createState() => _AddPortfolioItemScreenState();
}

class _AddPortfolioItemScreenState extends State<AddPortfolioItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _projectUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skillController = TextEditingController();
  
  final List<String> _skills = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _projectUrlController.dispose();
    _categoryController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createPortfolioItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        projectUrl: _projectUrlController.text.trim().isEmpty ? null : _projectUrlController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        skills: _skills.isEmpty ? null : _skills,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Работа добавлена в портфолио'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Text(
          'ДОБАВИТЬ РАБОТУ',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.tombstoneWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              AppTheme.gothicTextField(
                controller: _titleController,
                labelText: 'НАЗВАНИЕ РАБОТЫ *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Описание
              AppTheme.gothicTextField(
                controller: _descriptionController,
                labelText: 'ОПИСАНИЕ',
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Категория
              AppTheme.gothicTextField(
                controller: _categoryController,
                labelText: 'КАТЕГОРИЯ',
              ),
              const SizedBox(height: 20),

              // URL изображения
              AppTheme.gothicTextField(
                controller: _imageUrlController,
                labelText: 'ССЫЛКА НА ИЗОБРАЖЕНИЕ',
              ),
              const SizedBox(height: 20),

              // URL проекта
              AppTheme.gothicTextField(
                controller: _projectUrlController,
                labelText: 'ССЫЛКА НА ПРОЕКТ',
              ),
              const SizedBox(height: 20),

              // Навыки
              Text(
                'НАВЫКИ',
                style: TextStyle(
                  color: AppTheme.dimGray,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      style: const TextStyle(color: AppTheme.tombstoneWhite),
                      decoration: InputDecoration(
                        hintText: 'Например: Flutter',
                        hintStyle: TextStyle(color: AppTheme.dimGray),
                        filled: true,
                        fillColor: AppTheme.charcoal,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.dimGray),
                          borderRadius: BorderRadius.zero,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.dimGray),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.tombstoneWhite),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.tombstoneWhite),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.tombstoneWhite),
                      onPressed: _addSkill,
                    ),
                  ),
                ],
              ),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.tombstoneWhite.withOpacity(0.1),
                        border: Border.all(color: AppTheme.tombstoneWhite),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            skill,
                            style: const TextStyle(
                              color: AppTheme.tombstoneWhite,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _removeSkill(skill),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.dimGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 30),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tombstoneWhite,
                    foregroundColor: AppTheme.charcoal,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                          ),
                        )
                      : const Text(
                          'ДОБАВИТЬ В ПОРТФОЛИО',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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

