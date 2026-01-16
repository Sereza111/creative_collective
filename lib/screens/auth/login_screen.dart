import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Успешный вход - переходим на главный экран
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo/Title
                Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 80,
                      color: AppTheme.tombstoneWhite,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CREATIVE COLLECTIVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.tombstoneWhite,
                        letterSpacing: 4,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: 200,
                      color: AppTheme.dimGray,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ВХОД В СИСТЕМУ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mistGray,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),

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

                const SizedBox(height: 24),

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

                const SizedBox(height: 40),

                // Login button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
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
                            'ВОЙТИ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Нет аккаунта?',
                      style: TextStyle(
                        color: AppTheme.mistGray,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'ЗАРЕГИСТРИРОВАТЬСЯ',
                        style: TextStyle(
                          color: AppTheme.tombstoneWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
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

