import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty 
              ? null 
              : _fullNameController.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.tombstoneWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'РЕГИСТРАЦИЯ',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  decoration: InputDecoration(
                    labelText: 'ИМЯ ПОЛЬЗОВАТЕЛЯ',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.mistGray),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя пользователя';
                    }
                    if (value.length < 3) {
                      return 'Минимум 3 символа';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Full name field (optional)
                TextFormField(
                  controller: _fullNameController,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  decoration: InputDecoration(
                    labelText: 'ПОЛНОЕ ИМЯ (необязательно)',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.mistGray),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  decoration: InputDecoration(
                    labelText: 'EMAIL',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.mistGray),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@')) {
                      return 'Неверный формат email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  decoration: InputDecoration(
                    labelText: 'ПАРОЛЬ',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.mistGray),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.mistGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть минимум 6 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  decoration: InputDecoration(
                    labelText: 'ПОДТВЕРДИТЕ ПАРОЛЬ',
                    labelStyle: TextStyle(
                      color: AppTheme.mistGray,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.mistGray),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.mistGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.dimGray),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.tombstoneWhite, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.bloodRed, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Register button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tombstoneWhite,
                      foregroundColor: AppTheme.voidBlack,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                    ),
                    child: authState.isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.voidBlack),
                            ),
                          )
                        : Text(
                            'СОЗДАТЬ АККАУНТ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3,
                            ),
                          ),
                  ),
                ),

                // Error message
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.bloodRed),
                      color: AppTheme.bloodRed.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.bloodRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(
                              color: AppTheme.bloodRed,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

