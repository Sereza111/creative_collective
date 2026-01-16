import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'user_profile_screen.dart';

class FreelancersSearchScreen extends ConsumerStatefulWidget {
  const FreelancersSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FreelancersSearchScreen> createState() => _FreelancersSearchScreenState();
}

class _FreelancersSearchScreenState extends ConsumerState<FreelancersSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _freelancers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _verifiedOnly = false;
  double _minRating = 0;
  String? _categoryFilter;
  String _sortBy = 'rating'; // rating, reviews_count, created_at

  final List<String> _categories = [
    'Дизайн',
    'Разработка',
    'Маркетинг',
    'Копирайтинг',
    'Видеомонтаж',
    'Фотография',
    'Переводы',
    'Консалтинг',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _loadFreelancers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFreelancers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: 'freelancer',
      );
      
      List<dynamic> freelancers = response['users'] ?? [];
      
      // Фильтрация по верификации
      if (_verifiedOnly) {
        freelancers = freelancers.where((f) => f['is_verified'] == 1 || f['is_verified'] == true).toList();
      }
      
      // Фильтрация по рейтингу
      if (_minRating > 0) {
        freelancers = freelancers.where((f) {
          final rating = f['average_rating'];
          if (rating == null) return false;
          final ratingValue = rating is String ? double.tryParse(rating) ?? 0 : rating.toDouble();
          return ratingValue >= _minRating;
        }).toList();
      }
      
      // Фильтрация по категории
      if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
        freelancers = freelancers.where((f) {
          final categories = f['categories'];
          if (categories == null) return false;
          return categories.toString().contains(_categoryFilter!);
        }).toList();
      }
      
      // Сортировка
      freelancers.sort((a, b) {
        switch (_sortBy) {
          case 'rating':
            final ratingA = a['average_rating'];
            final ratingB = b['average_rating'];
            final valA = ratingA is String ? double.tryParse(ratingA) ?? 0 : (ratingA?.toDouble() ?? 0);
            final valB = ratingB is String ? double.tryParse(ratingB) ?? 0 : (ratingB?.toDouble() ?? 0);
            return valB.compareTo(valA); // По убыванию
          case 'reviews_count':
            return (b['reviews_count'] ?? 0).compareTo(a['reviews_count'] ?? 0);
          case 'created_at':
            return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
          default:
            return 0;
        }
      });
      
      setState(() {
        _freelancers = freelancers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки фрилансеров: $e')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.midnightBlack,
          title: Text('ФИЛЬТРЫ', style: TextStyle(color: AppTheme.tombstoneWhite)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Только верифицированные
                CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.electricBlue, size: 20),
                      const SizedBox(width: 8),
                      Text('Только верифицированные', style: TextStyle(color: AppTheme.tombstoneWhite)),
                    ],
                  ),
                  value: _verifiedOnly,
                  onChanged: (value) {
                    setDialogState(() => _verifiedOnly = value ?? false);
                  },
                  activeColor: AppTheme.electricBlue,
                  checkColor: AppTheme.midnightBlack,
                ),
                const SizedBox(height: 16),
                
                // Минимальный рейтинг
                Text('Минимальный рейтинг: ${_minRating.toStringAsFixed(1)} ⭐', 
                     style: TextStyle(color: AppTheme.mistGray)),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setDialogState(() => _minRating = value);
                  },
                  activeColor: AppTheme.goldenrod,
                  inactiveColor: AppTheme.ashGray,
                ),
                const SizedBox(height: 16),
                
                // Категория
                Text('Категория:', style: TextStyle(color: AppTheme.mistGray)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _categoryFilter,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.charcoalGray,
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.ashGray)),
                  ),
                  dropdownColor: AppTheme.charcoalGray,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Все', style: TextStyle(color: AppTheme.mistGray))),
                    ..._categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: TextStyle(color: AppTheme.tombstoneWhite)),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _categoryFilter = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Сортировка
                Text('Сортировка:', style: TextStyle(color: AppTheme.mistGray)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.charcoalGray,
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.ashGray)),
                  ),
                  dropdownColor: AppTheme.charcoalGray,
                  style: TextStyle(color: AppTheme.tombstoneWhite),
                  items: const [
                    DropdownMenuItem(value: 'rating', child: Text('По рейтингу')),
                    DropdownMenuItem(value: 'reviews_count', child: Text('По отзывам')),
                    DropdownMenuItem(value: 'created_at', child: Text('Сначала новые')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => _sortBy = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _verifiedOnly = false;
                  _minRating = 0;
                  _categoryFilter = null;
                  _sortBy = 'rating';
                });
                Navigator.pop(context);
                _loadFreelancers();
              },
              child: Text('СБРОСИТЬ', style: TextStyle(color: AppTheme.mistGray)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadFreelancers();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tombstoneWhite),
              child: Text('ПРИМЕНИТЬ', style: TextStyle(color: AppTheme.midnightBlack)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ПОИСК ФРИЛАНСЕРОВ'),
        backgroundColor: AppTheme.midnightBlack,
      ),
      backgroundColor: AppTheme.midnightBlack,
      body: Column(
        children: [
          // Поиск и фильтры
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.charcoalGray,
              border: Border(bottom: BorderSide(color: AppTheme.ashGray, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppTheme.tombstoneWhite),
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени, email, навыкам...',
                      hintStyle: TextStyle(color: AppTheme.mistGray),
                      prefixIcon: Icon(Icons.search, color: AppTheme.mistGray),
                      filled: true,
                      fillColor: AppTheme.midnightBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.ashGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.ashGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.tombstoneWhite),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    onSubmitted: (_) => _loadFreelancers(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.filter_list, color: AppTheme.tombstoneWhite),
                  onPressed: _showFilterDialog,
                  tooltip: 'Фильтры',
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppTheme.tombstoneWhite),
                  onPressed: _loadFreelancers,
                  tooltip: 'Обновить',
                ),
              ],
            ),
          ),

          // Активные фильтры
          if (_verifiedOnly || _minRating > 0 || _categoryFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.charcoalGray,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_verifiedOnly)
                    Chip(
                      label: Text('Верифицированные', style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 12)),
                      backgroundColor: AppTheme.electricBlue.withOpacity(0.2),
                      deleteIcon: Icon(Icons.close, size: 16, color: AppTheme.tombstoneWhite),
                      onDeleted: () {
                        setState(() => _verifiedOnly = false);
                        _loadFreelancers();
                      },
                    ),
                  if (_minRating > 0)
                    Chip(
                      label: Text('Рейтинг от ${_minRating.toStringAsFixed(1)}', 
                                   style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 12)),
                      backgroundColor: AppTheme.goldenrod.withOpacity(0.2),
                      deleteIcon: Icon(Icons.close, size: 16, color: AppTheme.tombstoneWhite),
                      onDeleted: () {
                        setState(() => _minRating = 0);
                        _loadFreelancers();
                      },
                    ),
                  if (_categoryFilter != null)
                    Chip(
                      label: Text(_categoryFilter!, style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 12)),
                      backgroundColor: AppTheme.ashGray.withOpacity(0.3),
                      deleteIcon: Icon(Icons.close, size: 16, color: AppTheme.tombstoneWhite),
                      onDeleted: () {
                        setState(() => _categoryFilter = null);
                        _loadFreelancers();
                      },
                    ),
                ],
              ),
            ),

          // Список фрилансеров
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.tombstoneWhite))
                : _freelancers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppTheme.mistGray),
                            const SizedBox(height: 16),
                            Text(
                              'Фрилансеры не найдены',
                              style: TextStyle(color: AppTheme.mistGray, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Попробуйте изменить фильтры',
                              style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFreelancers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _freelancers.length,
                          itemBuilder: (context, index) {
                            final freelancer = _freelancers[index];
                            return _buildFreelancerCard(freelancer);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreelancerCard(Map<String, dynamic> freelancer) {
    final isVerified = freelancer['is_verified'] == 1 || freelancer['is_verified'] == true;
    final rating = freelancer['average_rating'];
    final ratingValue = rating == null 
        ? null 
        : (rating is String ? double.tryParse(rating) : rating.toDouble());
    final reviewsCount = freelancer['reviews_count'] ?? 0;
    final skills = freelancer['skills']?.toString().split(',').take(3).toList() ?? [];

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
                builder: (context) => UserProfileScreen(userId: freelancer['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Аватар
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.ashGray,
                      backgroundImage: freelancer['avatar_url'] != null
                          ? NetworkImage(freelancer['avatar_url'])
                          : null,
                      child: freelancer['avatar_url'] == null
                          ? Text(
                              freelancer['full_name']?[0]?.toUpperCase() ?? 'F',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.tombstoneWhite,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Имя и рейтинг
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  freelancer['full_name'] ?? 'Без имени',
                                  style: TextStyle(
                                    color: AppTheme.tombstoneWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.verified, color: AppTheme.electricBlue, size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (ratingValue != null && reviewsCount > 0)
                            Row(
                              children: [
                                Icon(Icons.star, color: AppTheme.goldenrod, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${ratingValue.toStringAsFixed(1)} ($reviewsCount отзывов)',
                                  style: TextStyle(
                                    color: AppTheme.goldenrod,
                                    fontSize: 14,
                                  ),
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
                  ],
                ),
                
                // Биография
                if (freelancer['bio'] != null && freelancer['bio'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    freelancer['bio'],
                    style: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Навыки
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                
                // Кнопка "Смотреть профиль"
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: freelancer['id']),
                            ),
                          );
                        },
                        icon: Icon(Icons.person, size: 16, color: AppTheme.tombstoneWhite),
                        label: Text(
                          'СМОТРЕТЬ ПРОФИЛЬ',
                          style: TextStyle(
                            color: AppTheme.tombstoneWhite,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.ashGray),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

