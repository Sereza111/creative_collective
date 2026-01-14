import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _fullNameController.text = user.fullName ?? '';
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ApiService.updateUserProfile({
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
        });

        // Refresh user data
        await ref.read(authProvider.notifier).refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Профиль обновлен'),
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
              content: Text(e.toString().replaceAll('Exception: ', '')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('РЕДАКТИРОВАТЬ ПРОФИЛЬ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTheme.fadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ИМЯ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTheme.gothicTextField(
                      controller: _fullNameController,
                      hintText: 'Введите ваше полное имя',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите имя';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTheme.gothicTextField(
                      controller: _emailController,
                      hintText: 'Введите email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1100),
                child: AppTheme.gothicButton(
                  text: _isSubmitting ? 'Сохранение...' : 'Сохранить',
                  onPressed: _isSubmitting ? null : () => _submitForm(),
                  isPrimary: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1200),
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

