import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/order.dart';
import '../models/order_application.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  List<OrderApplication>? _applications;
  bool _isLoadingApplications = false;

  @override
  void initState() {
    super.initState();
    _loadApplicationsIfNeeded();
  }

  Future<void> _loadApplicationsIfNeeded() async {
    final user = ref.read(authProvider).user;
    if (user?.id == widget.order.clientId) {
      setState(() {
        _isLoadingApplications = true;
      });
      try {
        final applications = await ApiService.getApplicationsForOrder(widget.order.id);
        if (mounted) {
          setState(() {
            _applications = applications;
            _isLoadingApplications = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingApplications = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    final isFreelancer = user?.userRole == 'freelancer';
    final isClient = user?.userRole == 'client';
    final isOwner = user?.id == widget.order.clientId;

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
                              widget.order.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.tombstoneWhite,
                                letterSpacing: 3,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                          AppTheme.gothicBadge(widget.order.getStatusLabel()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (widget.order.description != null) ...[
                        Text(
                          widget.order.description!,
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
                      if (widget.order.budget != null) ...[
                        _buildInfoRow('БЮДЖЕТ', currencyFormat.format(widget.order.budget), Icons.attach_money),
                        const SizedBox(height: 16),
                      ],
                      if (widget.order.deadline != null) ...[
                        _buildInfoRow(
                          'ДЕДЛАЙН',
                          DateFormat('dd.MM.yyyy').format(widget.order.deadline!),
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.order.category != null) ...[
                        _buildInfoRow('КАТЕГОРИЯ', widget.order.category!.toUpperCase(), Icons.category_outlined),
                        const SizedBox(height: 16),
                      ],
                      _buildInfoRow('ЗАКАЗЧИК', widget.order.clientName ?? widget.order.clientEmail ?? 'Не указан', Icons.person_outline),
                      if (widget.order.freelancerName != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow('ИСПОЛНИТЕЛЬ', widget.order.freelancerName!, Icons.engineering_outlined),
                      ],
                      const SizedBox(height: 16),
                      _buildInfoRow('ОТКЛИКОВ', widget.order.applicationsCount.toString(), Icons.people_outline),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Кнопка откликнуться для фрилансеров
            if (isFreelancer && widget.order.status == 'published' && widget.order.freelancerId == null) ...[
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 700),
                child: AppTheme.gothicButton(
                  text: 'Откликнуться на заказ',
                  onPressed: () => _applyToOrder(context, ref),
                  isPrimary: true,
                ),
              ),
            ],
            // Список откликов для владельца заказа
            if (isOwner && widget.order.applicationsCount > 0) ...[
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ОТКЛИКИ НА ЗАКАЗ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.tombstoneWhite,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingApplications)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
                        ),
                      )
                    else if (_applications != null)
                      ..._applications!.map((app) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildApplicationCard(app, currencyFormat),
                      )).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(OrderApplication application, NumberFormat currencyFormat) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.freelancerName?.toUpperCase() ?? application.freelancerEmail.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.tombstoneWhite,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(application.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mistGray,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTheme.gothicBadge(application.getStatusLabel()),
              ],
            ),
            if (application.message != null && application.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                application.message!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.ashGray,
                  height: 1.6,
                ),
              ),
            ],
            if (application.proposedBudget != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 14, color: AppTheme.mistGray),
                  const SizedBox(width: 6),
                  Text(
                    'Предложение: ${currencyFormat.format(application.proposedBudget)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.ashGray,
                    ),
                  ),
                ],
              ),
            ],
            if (application.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTheme.gothicButton(
                      text: 'Принять',
                      onPressed: () => _acceptApplication(application.id),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTheme.gothicButton(
                      text: 'Отклонить',
                      onPressed: () => _rejectApplication(application.id),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptApplication(int applicationId) async {
    try {
      await ApiService.acceptApplication(widget.order.id, applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отклик принят!'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
        Navigator.pop(context, true); // Возвращаемся и обновляем список
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectApplication(int applicationId) async {
    try {
      await ApiService.rejectApplication(widget.order.id, applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отклик отклонён'),
            backgroundColor: AppTheme.shadowGray,
          ),
        );
        _loadApplicationsIfNeeded(); // Перезагружаем список откликов
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
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
        await ApiService.applyToOrder(widget.order.id, {
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
          Navigator.pop(context, true); // Возвращаемся и обновляем список
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

