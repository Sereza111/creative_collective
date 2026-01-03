import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/finance_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String _selectedType = 'earned'; // 'earned', 'spent', 'bonus', 'penalty'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final transactionData = {
        'type': _selectedType,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        'category': _categoryController.text.isNotEmpty ? _categoryController.text : null,
      };

      await ref.read(transactionsProvider.notifier).addTransaction(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Транзакция добавлена'),
            backgroundColor: AppTheme.shadowGray,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.bloodRed,
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: const Text('НОВАЯ ТРАНЗАКЦИЯ'),
        backgroundColor: AppTheme.darkerCharcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Тип транзакции
              Text(
                'ТИП ТРАНЗАКЦИИ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTypeChip('earned', 'Доход', Icons.add),
                  _buildTypeChip('spent', 'Расход', Icons.remove),
                  _buildTypeChip('bonus', 'Бонус', Icons.star_border),
                  _buildTypeChip('penalty', 'Штраф', Icons.warning_amber_outlined),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Сумма
              Text(
                'СУММА',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите сумму',
                  hintStyle: TextStyle(color: AppTheme.mistGray.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.darkerCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: const BorderSide(color: AppTheme.ashGray),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Неверный формат суммы';
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Описание транзакции',
                  hintStyle: TextStyle(color: AppTheme.mistGray.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.darkerCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: const BorderSide(color: AppTheme.ashGray),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Категория
              Text(
                'КАТЕГОРИЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Категория (опционально)',
                  hintStyle: TextStyle(color: AppTheme.mistGray.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.darkerCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: const BorderSide(color: AppTheme.ashGray),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.dimGray.withOpacity(0.5)),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text(
                        'ОТМЕНА',
                        style: TextStyle(
                          color: AppTheme.ashGray,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ashGray,
                        foregroundColor: AppTheme.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                            ),
                          )
                        : const Text(
                            'ДОБАВИТЬ',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ashGray.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.ashGray : AppTheme.dimGray.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.ashGray : AppTheme.mistGray,
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: isSelected ? AppTheme.ashGray : AppTheme.mistGray,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

