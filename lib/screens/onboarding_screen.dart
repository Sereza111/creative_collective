import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.handshake_outlined,
      title: 'ДОБРО ПОЖАЛОВАТЬ',
      subtitle: 'Creative Collective',
      description: 'Биржа фриланса нового поколения\nСвязываем заказчиков и исполнителей',
    ),
    OnboardingPage(
      icon: Icons.shopping_bag_outlined,
      title: 'МАРКЕТПЛЕЙС ЗАКАЗОВ',
      subtitle: 'Найдите идеальный проект',
      description: 'Тысячи заказов от реальных клиентов\nРаботайте над интересными задачами',
    ),
    OnboardingPage(
      icon: Icons.star_outline,
      title: 'РЕЙТИНГИ И ОТЗЫВЫ',
      subtitle: 'Стройте репутацию',
      description: 'Система оценок и отзывов\nПортфолио ваших работ\nВерифицированные аккаунты',
    ),
    OnboardingPage(
      icon: Icons.chat_bubble_outline,
      title: 'БЕЗОПАСНЫЕ ЧАТЫ',
      subtitle: 'Общайтесь напрямую',
      description: 'Встроенный мессенджер для работы\nОбсуждайте детали заказа\nБыстрая связь с клиентом',
    ),
    OnboardingPage(
      icon: Icons.account_balance_wallet_outlined,
      title: 'НАЧНИТЕ ЗАРАБАТЫВАТЬ',
      subtitle: 'Готовы к работе?',
      description: 'Зарегистрируйтесь как фрилансер или клиент\nНачните работу прямо сейчас!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка "Пропустить"
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'ПРОПУСТИТЬ',
                      style: TextStyle(
                        color: AppTheme.mistGray,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // Страницы
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Индикаторы
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 32 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.tombstoneWhite
                          : AppTheme.ashGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Кнопка "Далее" / "Начать"
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tombstoneWhite,
                    foregroundColor: AppTheme.midnightBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'ДАЛЕЕ' : 'НАЧАТЬ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка
          AppTheme.fadeInAnimation(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.ashGray.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                page.icon,
                size: 80,
                color: AppTheme.tombstoneWhite,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Заголовок
          AppTheme.fadeInAnimation(
            duration: const Duration(milliseconds: 800),
            child: Text(
              page.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.tombstoneWhite,
                letterSpacing: 3,
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Подзаголовок
          AppTheme.fadeInAnimation(
            duration: const Duration(milliseconds: 1000),
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.ashGray,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Описание
          AppTheme.fadeInAnimation(
            duration: const Duration(milliseconds: 1200),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mistGray,
                height: 1.8,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

