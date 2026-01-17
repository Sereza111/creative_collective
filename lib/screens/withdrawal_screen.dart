import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/finance_provider.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentDetailsController = TextEditingController();
  
  String _selectedMethod = 'card'; // 'card', 'qiwi', 'yoomoney'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _paymentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final balanceState = ref.read(balanceProvider);
    final balance = balanceState.balance?.balance ?? 0;
    final amount = double.parse(_amountController.text);

    if (amount > balance) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Недостаточно средств на балансе'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final methodNames = {
        'card': 'Банковская карта',
        'qiwi': 'QIWI кошелек',
        'yoomoney': 'ЮMoney',
      };

      await ApiService.createWithdrawalRequest(
        amount: amount,
        paymentMethod: methodNames[_selectedMethod]!,
        paymentDetails: _paymentDetailsController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Запрос на вывод средств отправлен'),
            backgroundColor: AppTheme.gothicGreen,
          ),
        );
        // Обновляем баланс
        ref.read(balanceProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
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
    final balanceState = ref.watch(balanceProvider);
    final balance = balanceState.balance?.balance ?? 0;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: Text('ВЫВОД СРЕДСТВ'),
        backgroundColor: AppTheme.darkerCharcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Доступный баланс
              AppTheme.animatedGothicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ДОСТУПНО К ВЫВОДУ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.mistGray,
                          letterSpacing: 3.0,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormat.format(balance),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          color: AppTheme.ghostWhite,
                          fontFamily: 'serif',
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Сумма
              Text(
                'СУММА ВЫВОДА',
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите сумму',
                  hintStyle: TextStyle(color: AppTheme.mistGray.withValues(alpha: 0.5)),
                  suffixText: '₽',
                  filled: true,
                  fillColor: AppTheme.darkerCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.ashGray),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Неверная сумма';
                  }
                  if (amount < 100) {
                    return 'Минимальная сумма: 100 ₽';
                  }
                  if (amount > balance) {
                    return 'Недостаточно средств';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Метод вывода
              Text(
                'МЕТОД ВЫВОДА',
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
                  _buildMethodChip('card', 'Банковская карта', Icons.credit_card),
                  _buildMethodChip('qiwi', 'QIWI', Icons.account_balance_wallet),
                  _buildMethodChip('yoomoney', 'ЮMoney', Icons.money),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Реквизиты
              Text(
                _getPaymentDetailsLabel(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.mistGray,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paymentDetailsController,
                style: TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: _getPaymentDetailsHint(),
                  hintStyle: TextStyle(color: AppTheme.mistGray.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppTheme.darkerCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppTheme.ashGray),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите реквизиты';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Предупреждение
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.mistGray, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Заявка будет рассмотрена в течение 1-3 рабочих дней',
                        style: TextStyle(
                          color: AppTheme.mistGray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                        side: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.5)),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
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
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gothicGreen,
                        foregroundColor: AppTheme.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                            ),
                          )
                        : Text(
                            'ОТПРАВИТЬ ЗАЯВКУ',
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

  Widget _buildMethodChip(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ashGray.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.ashGray : AppTheme.dimGray.withValues(alpha: 0.3),
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

  String _getPaymentDetailsLabel() {
    switch (_selectedMethod) {
      case 'card':
        return 'НОМЕР КАРТЫ';
      case 'qiwi':
        return 'НОМЕР QIWI КОШЕЛЬКА';
      case 'yoomoney':
        return 'НОМЕР ЮMONEY';
      default:
        return 'РЕКВИЗИТЫ';
    }
  }

  String _getPaymentDetailsHint() {
    switch (_selectedMethod) {
      case 'card':
        return '0000 0000 0000 0000';
      case 'qiwi':
        return '+7 (900) 000-00-00';
      case 'yoomoney':
        return '41001234567890';
      default:
        return 'Введите реквизиты';
    }
  }
}

