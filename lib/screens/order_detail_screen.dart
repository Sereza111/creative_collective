import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/order.dart';
import '../models/order_application.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'forms/add_review_screen.dart';
import 'legal_document_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  List<OrderApplication>? _applications;
  bool _isLoadingApplications = false;
  List<Review>? _reviews;
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _loadApplicationsIfNeeded();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await ApiService.getOrderReviews(widget.order.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
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

  Future<void> _completeOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ЗАВЕРШИТЬ ЗАКАЗ',
          style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите завершить этот заказ?',
              style: TextStyle(color: AppTheme.mistGray),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dimGray.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Будет произведена оплата:',
                    style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Фрилансеру: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format((widget.order.budget ?? 0) * 0.9)}',
                    style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 13),
                  ),
                  Text(
                    '• Комиссия: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format((widget.order.budget ?? 0) * 0.1)}',
                    style: TextStyle(color: AppTheme.ashGray, fontSize: 12),
                  ),
                  const Divider(color: AppTheme.dimGray),
                  Text(
                    'Итого: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(widget.order.budget ?? 0)}',
                    style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ОТМЕНА', style: TextStyle(color: AppTheme.mistGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gothicGreen,
              foregroundColor: AppTheme.charcoal,
            ),
            child: Text('ЗАВЕРШИТЬ', style: TextStyle(letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.completeOrder(widget.order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ завершен, оплата произведена'),
              backgroundColor: AppTheme.gothicGreen,
            ),
          );
          Navigator.pop(context, true); // Возвращаемся с результатом
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
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ОТМЕНИТЬ ЗАКАЗ',
          style: TextStyle(color: AppTheme.bloodRed, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вы уверены, что хотите отменить этот заказ?',
              style: TextStyle(color: AppTheme.mistGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Причина отмены',
                labelStyle: TextStyle(color: AppTheme.mistGray),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.dimGray),
                ),
              ),
              style: TextStyle(color: AppTheme.tombstoneWhite),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('НЕТ', style: TextStyle(color: AppTheme.mistGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bloodRed,
              foregroundColor: Colors.white,
            ),
            child: Text('ОТМЕНИТЬ ЗАКАЗ', style: TextStyle(letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.cancelOrder(widget.order.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ отменен'),
              backgroundColor: AppTheme.ashGray,
            ),
          );
          Navigator.pop(context, true); // Возвращаемся с результатом
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
      }
    }
    reasonController.dispose();
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
        actions: [
          // Кнопка чата (если фрилансер назначен)
          if (widget.order.freelancerId != null && 
              (user?.id == widget.order.clientId || user?.id == widget.order.freelancerId))
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () async {
                try {
                  final chat = await ApiService.getOrCreateChatForOrder(widget.order.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chat: chat),
                      ),
                    );
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
              },
              tooltip: 'Чат с исполнителем',
            ),
        ],
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
            
            // Кнопки управления заказом
            if (user != null && widget.order.status == 'in_progress') ...[
              const SizedBox(height: 24),
              // Кнопка завершения для заказчика
              if (user.id == widget.order.clientId)
                AppTheme.gothicButton(
                  text: 'ЗАВЕРШИТЬ ЗАКАЗ',
                  onPressed: () => _completeOrder(context),
                  isPrimary: true,
                ),
              const SizedBox(height: 12),
              // Кнопка отмены
              if (user.id == widget.order.clientId || user.id == widget.order.freelancerId)
                OutlinedButton(
                  onPressed: () => _cancelOrder(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.bloodRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'ОТМЕНИТЬ ЗАКАЗ',
                    style: TextStyle(
                      color: AppTheme.bloodRed,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
            ],
            
            // Кнопка для добавления отзыва (если заказ завершен)
            if (widget.order.status == 'completed' && 
                user != null &&
                (user.id == widget.order.clientId || user.id == widget.order.freelancerId)) ...[
              const SizedBox(height: 24),
              _buildReviewButton(user.id),
            ],
            
            // Отзывы
            if (_reviews != null && _reviews!.isNotEmpty) ...[
              const SizedBox(height: 24),
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ОТЗЫВЫ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.tombstoneWhite,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._reviews!.map((review) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildReviewCard(review),
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

  Widget _buildReviewButton(int userId) {
    // Проверяем, оставил ли пользователь уже отзыв
    final hasReviewed = _reviews?.any((r) => r.reviewerId == userId) ?? false;
    
    if (hasReviewed) {
      return Container();
    }

    return AppTheme.gothicButton(
      text: 'ОСТАВИТЬ ОТЗЫВ',
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReviewScreen(order: widget.order),
          ),
        );
        
        if (result == true) {
          _loadReviews(); // Перезагружаем отзывы
        }
      },
      isPrimary: false,
    );
  }

  Widget _buildReviewCard(Review review) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Аватар
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.darkerCharcoal,
                    border: Border.all(color: AppTheme.dimGray),
                  ),
                  child: review.reviewerAvatar != null
                      ? Image.network(review.reviewerAvatar!, fit: BoxFit.cover)
                      : Icon(Icons.person, color: AppTheme.mistGray, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName ?? review.reviewerEmail ?? 'Аноним',
                        style: const TextStyle(
                          color: AppTheme.tombstoneWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd.MM.yyyy').format(review.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.ashGray,
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 13,
                  height: 1.5,
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
                        (application.freelancerName ?? application.freelancerEmail ?? 'Фрилансер').toUpperCase(),
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
    // ПРОВЕРКА ПОДПИСИ ДОКУМЕНТОВ
    try {
      final hasSignedFreelancerTerms = await ApiService.checkUserAgreement('freelancer_terms');
      
      if (!hasSignedFreelancerTerms) {
        final signed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LegalDocumentScreen(
              documentType: 'freelancer_terms',
              title: 'Условия для фрилансеров',
            ),
          ),
        );
        
        if (signed != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Необходимо принять условия для продолжения'),
                backgroundColor: AppTheme.bloodRed,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка проверки документов: $e'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
      return;
    }

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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.charcoal,
                border: Border.all(color: AppTheme.dimGray.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.electricBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Стоимость отклика: 50 ₽',
                      style: TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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

  Future<void> _completeOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ЗАВЕРШИТЬ ЗАКАЗ',
          style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите завершить этот заказ?',
              style: TextStyle(color: AppTheme.mistGray),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dimGray.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Будет произведена оплата:',
                    style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Фрилансеру: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format((widget.order.budget ?? 0) * 0.9)}',
                    style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 13),
                  ),
                  Text(
                    '• Комиссия: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format((widget.order.budget ?? 0) * 0.1)}',
                    style: TextStyle(color: AppTheme.ashGray, fontSize: 12),
                  ),
                  const Divider(color: AppTheme.dimGray),
                  Text(
                    'Итого: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(widget.order.budget ?? 0)}',
                    style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ОТМЕНА', style: TextStyle(color: AppTheme.mistGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gothicGreen,
              foregroundColor: AppTheme.charcoal,
            ),
            child: Text('ЗАВЕРШИТЬ', style: TextStyle(letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.completeOrder(widget.order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ завершен, оплата произведена'),
              backgroundColor: AppTheme.gothicGreen,
            ),
          );
          Navigator.pop(context, true); // Возвращаемся с результатом
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
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkerCharcoal,
        title: Text(
          'ОТМЕНИТЬ ЗАКАЗ',
          style: TextStyle(color: AppTheme.bloodRed, fontSize: 14, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вы уверены, что хотите отменить этот заказ?',
              style: TextStyle(color: AppTheme.mistGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Причина отмены',
                labelStyle: TextStyle(color: AppTheme.mistGray),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.dimGray),
                ),
              ),
              style: TextStyle(color: AppTheme.tombstoneWhite),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('НЕТ', style: TextStyle(color: AppTheme.mistGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bloodRed,
              foregroundColor: Colors.white,
            ),
            child: Text('ОТМЕНИТЬ ЗАКАЗ', style: TextStyle(letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.cancelOrder(widget.order.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ отменен'),
              backgroundColor: AppTheme.ashGray,
            ),
          );
          Navigator.pop(context, true); // Возвращаемся с результатом
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
      }
    }
    reasonController.dispose();
  }
}

