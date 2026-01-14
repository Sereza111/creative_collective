import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends ConsumerWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    final isFreelancer = user?.userRole == 'freelancer';
    final isClient = user?.userRole == 'client';
    final isOwner = user?.id == order.clientId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ЗАКАЗ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.fadeInAnimation(
              child: AppTheme.animatedGothicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.tombstoneWhite,
                                letterSpacing: 3,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                          AppTheme.gothicBadge(order.getStatusLabel()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (order.description != null) ...[
                        Text(
                          order.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mistGray,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Container(height: 1, color: AppTheme.dimGray.withOpacity(0.3)),
                      const SizedBox(height: 24),
                      if (order.budget != null) ...[
                        _buildInfoRow('БЮДЖЕТ', currencyFormat.format(order.budget), Icons.attach_money),
                        const SizedBox(height: 16),
                      ],
                      if (order.deadline != null) ...[
                        _buildInfoRow(
                          'ДЕДЛАЙН',
                          DateFormat('dd.MM.yyyy').format(order.deadline!),
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (order.category != null) ...[
                        _buildInfoRow('КАТЕГОРИЯ', order.category!.toUpperCase(), Icons.category_outlined),
                        const SizedBox(height: 16),
                      ],
                      _buildInfoRow('ЗАКАЗЧИК', order.clientName ?? order.clientEmail ?? 'Не указан', Icons.person_outline),
                      if (order.freelancerName != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow('ИСПОЛНИТЕЛЬ', order.freelancerName!, Icons.engineering_outlined),
                      ],
                      const SizedBox(height: 16),
                      _buildInfoRow('ОТКЛИКОВ', order.applicationsCount.toString(), Icons.people_outline),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isFreelancer && order.status == 'published' && order.freelancerId == null) ...[
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 700),
                child: AppTheme.gothicButton(
                  text: 'Откликнуться на заказ',
                  onPressed: () => _applyToOrder(context, ref),
                  isPrimary: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.ashGray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.mistGray,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.tombstoneWhite,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _applyToOrder(BuildContext context, WidgetRef ref) async {
    final messageController = TextEditingController();
    final budgetController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ОТКЛИКНУТЬСЯ НА ЗАКАЗ',
          style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Сообщение',
                labelStyle: TextStyle(color: AppTheme.mistGray),
              ),
              style: TextStyle(color: AppTheme.tombstoneWhite),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              decoration: InputDecoration(
                labelText: 'Ваше предложение (₽)',
                labelStyle: TextStyle(color: AppTheme.mistGray),
              ),
              style: TextStyle(color: AppTheme.tombstoneWhite),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ОТМЕНА', style: TextStyle(color: AppTheme.mistGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ОТПРАВИТЬ', style: TextStyle(color: AppTheme.tombstoneWhite)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await ApiService.applyToOrder(order.id, {
          'message': messageController.text.trim(),
          'proposed_budget': budgetController.text.isNotEmpty ? double.parse(budgetController.text) : null,
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Отклик отправлен!'),
              backgroundColor: AppTheme.shadowGray,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.bloodRed,
            ),
          );
        }
      }
    }

    messageController.dispose();
    budgetController.dispose();
  }
}

