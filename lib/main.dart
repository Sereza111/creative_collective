import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/team_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/chats_list_with_search_screen.dart';
import 'screens/freelancers_search_screen.dart';
import 'screens/my_stats_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/withdrawal_screen.dart';
import 'screens/add_balance_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/unread_counter_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _onboardingCompleted = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
          _checkingOnboarding = false;
        });
      }
    } catch (e) {
      // Если ошибка - пропускаем онбординг
      if (mounted) {
        setState(() {
          _onboardingCompleted = true;
          _checkingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_checkingOnboarding) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.midnightBlack,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.tombstoneWhite),
          ),
        ),
        theme: AppTheme.darkTheme,
      );
    }

    return MaterialApp(
      title: 'Creative Collective',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: !_onboardingCompleted
          ? const OnboardingScreen()
          : authState.isLoading
              ? const SplashScreen()
              : authState.isAuthenticated
                  ? const MainScreen()
                  : const LoginScreen(),
      routes: {
        '/my_orders': (context) => const MyOrdersScreen(),
        '/my_applications': (context) => const MyApplicationsScreen(),
        '/admin_panel': (context) => const AdminPanelScreen(),
        '/freelancers_search': (context) => const FreelancersSearchScreen(),
        '/my_stats': (context) => const MyStatsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/withdrawal': (context) => const WithdrawalScreen(),
        '/add_balance': (context) => const AddBalanceScreen(),
        '/teams': (context) => const TeamScreen(),
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    ProjectsScreen(),
    MarketplaceScreen(),
    ChatsListWithSearchScreen(),
    FinanceScreen(),
    ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Главная'),
    NavigationItem(
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        label: 'Задачи'),
    NavigationItem(
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder_rounded,
        label: 'Проекты'),
    NavigationItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'Маркет'),
    NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Чаты'),
    NavigationItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Финансы'),
    NavigationItem(
        icon: Icons.person_outline, activeIcon: Icons.person, label: 'Профиль'),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCounterProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _screens[_selectedIndex],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopNavigation(
              selectedIndex: _selectedIndex,
              items: _navigationItems,
              unreadCount: unreadCount,
              onSelected: _onItemTapped,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: _onItemTapped,
        destinations: List.generate(_navigationItems.length, (index) {
          final item = _navigationItems[index];
          return NavigationDestination(
            icon: _NavigationIcon(
              icon: item.icon,
              unreadCount: index == 4 ? unreadCount : 0,
            ),
            selectedIcon: _NavigationIcon(
              icon: item.activeIcon,
              unreadCount: index == 4 ? unreadCount : 0,
            ),
            label: item.label,
            tooltip: item.label,
          );
        }),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.items,
    required this.unreadCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationItem> items;
  final int unreadCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      color: AppTheme.voidBlack,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _BrandMark(),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creative',
                            style: TextStyle(
                              color: AppTheme.ghostWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Collective',
                            style: TextStyle(
                              color: AppTheme.mistGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'РАБОЧЕЕ ПРОСТРАНСТВО',
                  style: TextStyle(
                    color: AppTheme.mistGray,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(items.length, (index) {
                final item = items[index];
                final selected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: selected
                        ? AppTheme.subtleAccent.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 22,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.subtleAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 11),
                            _NavigationIcon(
                              icon: selected ? item.activeIcon : item.icon,
                              unreadCount: index == 4 ? unreadCount : 0,
                              color: selected
                                  ? AppTheme.subtleAccent
                                  : AppTheme.mistGray,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected
                                    ? AppTheme.tombstoneWhite
                                    : AppTheme.ashGray,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Все рабочие данные собраны в одном месте.',
                  style: TextStyle(
                    color: AppTheme.mistGray,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.subtleAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.hub_outlined,
        color: AppTheme.deepBlack,
        size: 21,
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    this.unreadCount = 0,
    this.color,
  });

  final IconData icon;
  final int unreadCount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 22),
        if (unreadCount > 0)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppTheme.bloodRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
