import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/order.dart';

class AddReviewScreen extends StatefulWidget {
  final Order order;

  const AddReviewScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createReview(
        widget.order.id,
        _rating,
        _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Возвращаем true, чтобы обновить список
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
          'ОСТАВИТЬ ОТЗЫВ',
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
              // Информация о заказе
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  border: Border.all(color: AppTheme.dimGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЗАКАЗ',
                      style: TextStyle(
                        color: AppTheme.dimGray,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.order.title,
                      style: const TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Рейтинг
              Text(
                'ОЦЕНКА',
                style: TextStyle(
                  color: AppTheme.dimGray,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starValue;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          starValue <= _rating ? Icons.star : Icons.star_border,
                          size: 48,
                          color: starValue <= _rating
                              ? Colors.amber
                              : AppTheme.dimGray,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Комментарий
              Text(
                'КОММЕНТАРИЙ (необязательно)',
                style: TextStyle(
                  color: AppTheme.dimGray,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 6,
                maxLength: 2000,
                style: const TextStyle(color: AppTheme.tombstoneWhite),
                decoration: InputDecoration(
                  hintText: 'Напишите свое мнение о работе...',
                  hintStyle: TextStyle(color: AppTheme.dimGray),
                  filled: true,
                  fillColor: AppTheme.charcoal,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tombstoneWhite),
                    borderRadius: BorderRadius.zero,
                  ),
                  counterStyle: TextStyle(color: AppTheme.dimGray),
                ),
              ),

              const SizedBox(height: 30),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
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
                          'ОТПРАВИТЬ ОТЗЫВ',
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Отлично!';
      case 4:
        return 'Хорошо';
      case 3:
        return 'Нормально';
      case 2:
        return 'Плохо';
      case 1:
        return 'Ужасно';
      default:
        return '';
    }
  }
}

