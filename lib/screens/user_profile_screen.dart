import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/portfolio_item.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  List<PortfolioItem> _portfolioItems = [];
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingPortfolio = true;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadPortfolio();
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Используем API для получения данных пользователя
      final response = await ApiService.getAllUsers(role: null);
      final users = response['users'] as List;
      final user = users.firstWhere(
        (u) => u['id'] == widget.userId,
        orElse: () => null,
      );
      
      if (user != null) {
        setState(() {
          _userData = user;
          _isLoading = false;
        });
      } else {
        throw Exception('Пользователь не найден');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoadingPortfolio = true);
    try {
      final items = await ApiService.getPortfolioItems(widget.userId);
      setState(() {
        _portfolioItems = items;
        _isLoadingPortfolio = false;
      });
    } catch (e) {
      setState(() => _isLoadingPortfolio = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ApiService.getReviewsForUser(widget.userId);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      // Показываем загрузку
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppTheme.tombstoneWhite),
        ),
      );

      // Создаем временный чат без заказа (orderId = null)
      // Для этого нужно будет модифицировать backend, но пока используем workaround
      // Просто показываем сообщение что нужно связаться через заказ
      
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Для связи с фрилансером создайте заказ и пригласите его'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isOwnProfile = currentUser?.id == widget.userId;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Загрузка...'),
          backgroundColor: AppTheme.midnightBlack,
        ),
        backgroundColor: AppTheme.midnightBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite)),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
          backgroundColor: AppTheme.midnightBlack,
        ),
        backgroundColor: AppTheme.midnightBlack,
        body: Center(
          child: Text(
            'Пользователь не найден',
            style: TextStyle(color: AppTheme.mistGray),
          ),
        ),
      );
    }

    final isVerified = _userData!['is_verified'] == 1 || _userData!['is_verified'] == true;
    final rating = _userData!['average_rating'];
    final ratingValue = rating == null 
        ? null 
        : (rating is String ? double.tryParse(rating) : rating.toDouble());
    final reviewsCount = _userData!['reviews_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData!['full_name'] ?? 'Профиль'),
        backgroundColor: AppTheme.midnightBlack,
        actions: [
          if (!isOwnProfile && _userData!['user_role'] == 'freelancer')
            IconButton(
              icon: Icon(Icons.message, color: AppTheme.tombstoneWhite),
              onPressed: _startChat,
              tooltip: 'Написать',
            ),
        ],
      ),
      backgroundColor: AppTheme.midnightBlack,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Шапка профиля
            _buildProfileHeader(isVerified, ratingValue, reviewsCount),
            
            // Табы: Портфолио и Отзывы
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.ashGray, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.tombstoneWhite,
                unselectedLabelColor: AppTheme.mistGray,
                indicatorColor: AppTheme.tombstoneWhite,
                tabs: [
                  Tab(text: 'ПОРТФОЛИО (${_portfolioItems.length})'),
                  Tab(text: 'ОТЗЫВЫ (${_reviews.length})'),
                ],
              ),
            ),
            
            // Контент табов
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPortfolioTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isVerified, double? ratingValue, int reviewsCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.charcoalGray,
        border: Border(bottom: BorderSide(color: AppTheme.ashGray, width: 1)),
      ),
      child: Column(
        children: [
          // Аватар
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.ashGray,
            backgroundImage: _userData!['avatar_url'] != null
                ? NetworkImage(_userData!['avatar_url'])
                : null,
            child: _userData!['avatar_url'] == null
                ? Text(
                    _userData!['full_name']?[0]?.toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.tombstoneWhite,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Имя и верификация
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userData!['full_name'] ?? 'Без имени',
                style: TextStyle(
                  color: AppTheme.tombstoneWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified, color: AppTheme.electricBlue, size: 24),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            _userData!['email'] ?? '',
            style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Рейтинг
          if (ratingValue != null && reviewsCount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: AppTheme.goldenrod, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${ratingValue.toStringAsFixed(1)} ($reviewsCount отзывов)',
                  style: TextStyle(
                    color: AppTheme.goldenrod,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Text(
              'Пока нет отзывов',
              style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
            ),
          
          // Биография
          if (_userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _userData!['bio'],
              style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Навыки
          if (_userData!['skills'] != null && _userData!['skills'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _userData!['skills'].toString().split(',').map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.ashGray.withOpacity(0.3),
                  border: Border.all(color: AppTheme.ashGray),
                ),
                child: Text(
                  skill.trim(),
                  style: TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    if (_isLoadingPortfolio) {
      return Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite));
    }

    if (_portfolioItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: AppTheme.mistGray),
            const SizedBox(height: 16),
            Text(
              'Портфолио пока пусто',
              style: TextStyle(color: AppTheme.mistGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _portfolioItems.length,
      itemBuilder: (context, index) {
        final item = _portfolioItems[index];
        return _buildPortfolioCard(item);
      },
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.charcoalGray,
        border: Border.all(color: AppTheme.ashGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.ashGray,
                  border: Border(bottom: BorderSide(color: AppTheme.ashGray)),
                ),
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.image_not_supported, color: AppTheme.mistGray),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                color: AppTheme.ashGray,
                child: Center(
                  child: Icon(Icons.image, size: 48, color: AppTheme.mistGray),
                ),
              ),
            ),
          
          // Информация
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite));
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: AppTheme.mistGray),
            const SizedBox(height: 16),
            Text(
              'Отзывов пока нет',
              style: TextStyle(color: AppTheme.mistGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 0;
    final ratingValue = rating is String ? int.tryParse(rating) ?? 0 : rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalGray,
        border: Border.all(color: AppTheme.ashGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.ashGray,
                child: Text(
                  review['reviewer_name']?[0]?.toUpperCase() ?? 'R',
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewer_name'] ?? 'Аноним',
                      style: TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < ratingValue ? Icons.star : Icons.star_border,
                          color: AppTheme.goldenrod,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review['created_at'] != null 
                ? DateTime.parse(review['created_at']).toString().split(' ')[0]
                : '',
            style: TextStyle(color: AppTheme.mistGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

