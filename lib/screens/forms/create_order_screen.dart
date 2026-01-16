import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/orders_provider.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedCategory = 'design';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(ordersProvider.notifier).createOrder({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'budget': _budgetController.text.isNotEmpty ? double.parse(_budgetController.text) : null,
          'deadline': _selectedDeadline?.toIso8601String(),
          'category': _selectedCategory,
        });

        await ref.read(ordersProvider.notifier).loadOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ успешно создан'),
              backgroundColor: AppTheme.shadowGray,
            ),
          );
          Navigator.pop(context, true); // Возвращаем true для обновления списка
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка создания заказа: ${e.toString().replaceAll('Exception: ', '')}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('СОЗДАТЬ ЗАКАЗ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTheme.fadeInAnimation(
                child: AppTheme.gothicTextField(
                  controller: _titleController,
                  labelText: 'НАЗВАНИЕ ЗАКАЗА',
                  hintText: 'Введите название заказа',
                  icon: Icons.title,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите название';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 700),
                child: AppTheme.gothicTextField(
                  controller: _descriptionController,
                  labelText: 'ОПИСАНИЕ',
                  hintText: 'Опишите задачу',
                  icon: Icons.description_outlined,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите описание';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 900),
                child: AppTheme.gothicTextField(
                  controller: _budgetController,
                  labelText: 'БЮДЖЕТ',
                  hintText: 'Введите бюджет',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 20),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1100),
                child: AppTheme.gothicDropdown<String>(
                  value: _selectedCategory,
                  labelText: 'КАТЕГОРИЯ',
                  icon: Icons.category_outlined,
                  items: const [
                    DropdownMenuItem(value: 'design', child: Text('Дизайн')),
                    DropdownMenuItem(value: 'development', child: Text('Разработка')),
                    DropdownMenuItem(value: 'content', child: Text('Контент')),
                    DropdownMenuItem(value: 'marketing', child: Text('Маркетинг')),
                    DropdownMenuItem(value: 'other', child: Text('Другое')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1300),
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDeadline = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dimGray.withOpacity(0.3)),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.mistGray, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? 'ВЫБЕРИТЕ ДЕДЛАЙН'
                                : 'ДЕДЛАЙН: ${_selectedDeadline!.day}.${_selectedDeadline!.month}.${_selectedDeadline!.year}',
                            style: TextStyle(
                              color: _selectedDeadline == null ? AppTheme.mistGray : AppTheme.tombstoneWhite,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1500),
                child: AppTheme.gothicButton(
                  text: _isSubmitting ? 'Создание...' : 'Создать заказ',
                  onPressed: () => _submitForm(),
                  isPrimary: true,
                ),
              ),
              const SizedBox(height: 16),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1700),
                child: AppTheme.gothicButton(
                  text: 'Отмена',
                  onPressed: () => Navigator.pop(context),
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

