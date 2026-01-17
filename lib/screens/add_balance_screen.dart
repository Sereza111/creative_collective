import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/finance_provider.dart';

class AddBalanceScreen extends ConsumerStatefulWidget {
  const AddBalanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends ConsumerState<AddBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _selectedMethod = 'card'; // 'card', 'qiwi', 'yoomoney', 'sbp'
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 500, 'label': '500 ₽'},
    {'amount': 1000, 'label': '1 000 ₽'},
    {'amount': 5000, 'label': '5 000 ₽'},
    {'amount': 10000, 'label': '10 000 ₽'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      // TODO: Интеграция с реальной платёжной системой
      // Пока просто показываем инструкции
      
      await Future.delayed(Duration(seconds: 1)); // Имитация обработки

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.darkerCharcoal,
            title: Text(
              'ИНСТРУКЦИИ ПО ОПЛАТЕ',
              style: TextStyle(
                color: AppTheme.tombstoneWhite,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сумма: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(amount)}',
                    style: TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal,
                      border: Border.all(color: AppTheme.dimGray.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Метод оплаты: ${_getMethodName()}',
                          style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '⚠️ ВАЖНО: Платёжная система в разработке',
                          style: TextStyle(
                            color: AppTheme.bloodRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Для тестирования обратитесь к администратору для ручного пополнения баланса.',
                          style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Закрываем оба экрана
                },
                child: Text(
                  'ПОНЯТНО',
                  style: TextStyle(
                    color: AppTheme.tombstoneWhite,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
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
          _isProcessing = false;
        });
      }
    }
  }

  String _getMethodName() {
    switch (_selectedMethod) {
      case 'card':
        return 'Банковская карта';
      case 'qiwi':
        return 'QIWI кошелек';
      case 'yoomoney':
        return 'ЮMoney';
      case 'sbp':
        return 'СБП (Система быстрых платежей)';
      default:
        return 'Неизвестно';
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
        title: Text('ПОПОЛНЕНИЕ БАЛАНСА'),
        backgroundColor: AppTheme.darkerCharcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущий баланс
              AppTheme.animatedGothicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ТЕКУЩИЙ БАЛАНС',
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
              
              // Быстрый выбор суммы
              Text(
                'БЫСТРЫЙ ВЫБОР',
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
                children: _quickAmounts.map((item) {
                  return OutlinedButton(
                    onPressed: () => _setQuickAmount(item['amount'].toDouble()),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.dimGray.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      item['label'],
                      style: TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Сумма пополнения
              Text(
                'СУММА ПОПОЛНЕНИЯ',
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
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Метод оплаты
              Text(
                'МЕТОД ОПЛАТЫ',
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
                  _buildMethodChip('sbp', 'СБП', Icons.qr_code_2),
                  _buildMethodChip('qiwi', 'QIWI', Icons.account_balance_wallet),
                  _buildMethodChip('yoomoney', 'ЮMoney', Icons.money),
                ],
              ),
              
              const SizedBox(height: 48),
              
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
                        'Средства поступят на баланс мгновенно после оплаты',
                        style: TextStyle(
                          color: AppTheme.mistGray,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка оплаты
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gothicGreen,
                    foregroundColor: AppTheme.charcoal,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isProcessing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                        ),
                      )
                    : Text(
                        'ПОПОЛНИТЬ БАЛАНС',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
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
}

