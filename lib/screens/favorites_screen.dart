import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'order_detail_screen.dart';
import 'user_profile_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _favoriteOrders = [];
  List<dynamic> _favoriteFreelancers = [];
  bool _isLoadingOrders = true;
  bool _isLoadingFreelancers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    await Future.wait([
      _loadFavoriteOrders(),
      _loadFavoriteFreelancers(),
    ]);
  }

  Future<void> _loadFavoriteOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final favorites = await ApiService.getFavorites(itemType: 'order');
      setState(() {
        _favoriteOrders = favorites;
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() => _isLoadingOrders = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки избранных заказов: $e')),
        );
      }
    }
  }

  Future<void> _loadFavoriteFreelancers() async {
    setState(() => _isLoadingFreelancers = true);
    try {
      final favorites = await ApiService.getFavorites(itemType: 'freelancer');
      setState(() {
        _favoriteFreelancers = favorites;
        _isLoadingFreelancers = false;
      });
    } catch (e) {
      setState(() => _isLoadingFreelancers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки избранных фрилансеров: $e')),
        );
      }
    }
  }

  Future<void> _removeFavorite(String itemType, int itemId) async {
    try {
      await ApiService.removeFavorite(itemType, itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено из избранного')),
        );
      }
      _loadFavorites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ИЗБРАННОЕ'),
        backgroundColor: AppTheme.midnightBlack,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.tombstoneWhite,
          unselectedLabelColor: AppTheme.mistGray,
          indicatorColor: AppTheme.tombstoneWhite,
          tabs: [
            Tab(text: 'ЗАКАЗЫ (${_favoriteOrders.length})'),
            Tab(text: 'ФРИЛАНСЕРЫ (${_favoriteFreelancers.length})'),
          ],
        ),
      ),
      backgroundColor: AppTheme.midnightBlack,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildFreelancersTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite));
    }

    if (_favoriteOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.mistGray),
            const SizedBox(height: 16),
            Text(
              'Нет избранных заказов',
              style: TextStyle(color: AppTheme.mistGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteOrders.length,
        itemBuilder: (context, index) {
          final favorite = _favoriteOrders[index];
          return _buildOrderCard(favorite);
        },
      ),
    );
  }

  Widget _buildFreelancersTab() {
    if (_isLoadingFreelancers) {
      return Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite));
    }

    if (_favoriteFreelancers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppTheme.mistGray),
            const SizedBox(height: 16),
            Text(
              'Нет избранных фрилансеров',
              style: TextStyle(color: AppTheme.mistGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteFreelancers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteFreelancers.length,
        itemBuilder: (context, index) {
          final favorite = _favoriteFreelancers[index];
          return _buildFreelancerCard(favorite);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> favorite) {
    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGray,
          border: Border.all(color: AppTheme.ashGray, width: 1),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to order details (нужно получить полный Order объект)
            // Пока что просто показываем сообщение
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Перейдите в маркетплейс для просмотра заказа')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite['item_name'] ?? 'Без названия',
                        style: TextStyle(
                          color: AppTheme.tombstoneWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (favorite['item_budget'] != null)
                        Text(
                          'Бюджет: ${favorite['item_budget']} ₽',
                          style: TextStyle(color: AppTheme.goldenrod, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: AppTheme.bloodRed),
                  onPressed: () => _removeFavorite('order', favorite['item_id']),
                  tooltip: 'Удалить из избранного',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreelancerCard(Map<String, dynamic> favorite) {
    final rating = favorite['item_rating'];
    final ratingValue = rating == null 
        ? null 
        : (rating is String ? double.tryParse(rating) : rating.toDouble());
    final isVerified = favorite['item_is_verified'] == 1 || favorite['item_is_verified'] == true;

    return AppTheme.fadeInAnimation(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGray,
          border: Border.all(color: AppTheme.ashGray, width: 1),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: favorite['item_id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.ashGray,
                  backgroundImage: favorite['item_avatar'] != null
                      ? NetworkImage(favorite['item_avatar'])
                      : null,
                  child: favorite['item_avatar'] == null
                      ? Text(
                          favorite['item_name']?[0]?.toUpperCase() ?? 'F',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.tombstoneWhite,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              favorite['item_name'] ?? 'Без имени',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.verified, color: AppTheme.electricBlue, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (ratingValue != null)
                        Row(
                          children: [
                            Icon(Icons.star, color: AppTheme.goldenrod, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              ratingValue.toStringAsFixed(1),
                              style: TextStyle(color: AppTheme.goldenrod, fontSize: 14),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Новый фрилансер',
                          style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                
                // Кнопка удаления
                IconButton(
                  icon: Icon(Icons.favorite, color: AppTheme.bloodRed),
                  onPressed: () => _removeFavorite('freelancer', favorite['item_id']),
                  tooltip: 'Удалить из избранного',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

