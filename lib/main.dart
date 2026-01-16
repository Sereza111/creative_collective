import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/chats_list_screen.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Creative Collective',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: authState.isLoading
          ? const SplashScreen()
          : authState.isAuthenticated
              ? const MainScreen()
              : const LoginScreen(),
      routes: {
        '/my_orders': (context) => const MyOrdersScreen(),
        '/my_applications': (context) => const MyApplicationsScreen(),
      },
    );
  }
}

// Splash screen while checking auth
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: AppTheme.tombstoneWhite,
            ),
            const SizedBox(height: 24),
            Text(
              'CREATIVE COLLECTIVE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: AppTheme.tombstoneWhite,
                letterSpacing: 4,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const ProjectsScreen(),
    const MarketplaceScreen(),
    const ChatsListScreen(),
    const FinanceScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Главная'),
    NavigationItem(icon: Icons.checklist_outlined, activeIcon: Icons.checklist, label: 'Задачи'),
    NavigationItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Проекты'),
    NavigationItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Маркет'),
    NavigationItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Чаты'),
    NavigationItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Финансы'),
    NavigationItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Профиль'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.voidBlack,
          border: Border(
            top: BorderSide(
              color: AppTheme.dimGray.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navigationItems.length, (index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.shadowGray.withOpacity(0.2)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(
                                color: AppTheme.dimGray.withOpacity(0.5),
                                width: 1,
                              )
                            : null,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                            size: isSelected ? 24 : 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isSelected ? 9 : 8,
                              fontWeight: FontWeight.w300,
                              color: isSelected ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                              letterSpacing: isSelected ? 1.5 : 1.0,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
