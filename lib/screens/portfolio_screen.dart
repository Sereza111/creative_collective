import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/portfolio_item.dart';
import '../services/api_service.dart';
import 'forms/add_portfolio_item_screen.dart';

class PortfolioScreen extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;

  const PortfolioScreen({
    Key? key,
    required this.userId,
    this.isOwnProfile = false,
  }) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<PortfolioItem>? _items;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await ApiService.getUserPortfolio(widget.userId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        title: const Text('УДАЛИТЬ РАБОТУ?', style: TextStyle(color: AppTheme.tombstoneWhite)),
        content: const Text(
          'Это действие нельзя отменить',
          style: TextStyle(color: AppTheme.ghostWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ОТМЕНА', style: TextStyle(color: AppTheme.dimGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('УДАЛИТЬ', style: TextStyle(color: AppTheme.bloodRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deletePortfolioItem(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Работа удалена'),
              backgroundColor: AppTheme.shadowGray,
            ),
          );
          _loadPortfolio();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.bloodRed,
            ),
          );
        }
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
          'ПОРТФОЛИО',
          style: TextStyle(
            color: AppTheme.tombstoneWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.tombstoneWhite),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
              ),
            )
          : _items == null || _items!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 80,
                        color: AppTheme.dimGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isOwnProfile
                            ? 'Портфолио пусто\nДобавьте свои работы!'
                            : 'Портфолио пусто',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.dimGray,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPortfolio,
                  color: AppTheme.tombstoneWhite,
                  backgroundColor: AppTheme.charcoal,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _items!.length,
                    itemBuilder: (context, index) {
                      final item = _items![index];
                      return _buildPortfolioCard(item);
                    },
                  ),
                ),
      floatingActionButton: widget.isOwnProfile
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPortfolioItemScreen(),
                  ),
                );
                if (result == true) {
                  _loadPortfolio();
                }
              },
              backgroundColor: AppTheme.tombstoneWhite,
              icon: const Icon(Icons.add, color: AppTheme.charcoal),
              label: const Text(
                'ДОБАВИТЬ',
                style: TextStyle(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item) {
    return AppTheme.animatedGothicCard(
      child: InkWell(
        onTap: () => _showItemDetails(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppTheme.darkerCharcoal,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: AppTheme.dimGray,
                          );
                        },
                      )
                    : Icon(
                        Icons.work,
                        size: 40,
                        color: AppTheme.dimGray,
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
                    style: const TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.category!,
                      style: TextStyle(
                        color: AppTheme.dimGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (item.skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.skills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dimGray.withOpacity(0.3),
                            border: Border.all(color: AppTheme.dimGray),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: AppTheme.ghostWhite,
                              fontSize: 9,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(PortfolioItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.charcoal,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.bloodRed),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem(item.id);
                      },
                    ),
                ],
              ),
              if (item.category != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.category!,
                  style: TextStyle(
                    color: AppTheme.dimGray,
                    fontSize: 14,
                  ),
                ),
              ],
              if (item.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  item.description!,
                  style: const TextStyle(
                    color: AppTheme.ghostWhite,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              if (item.skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.dimGray.withOpacity(0.3),
                        border: Border.all(color: AppTheme.dimGray),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: AppTheme.ghostWhite,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (item.projectUrl != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    // TODO: Открыть URL
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: AppTheme.tombstoneWhite, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.projectUrl!,
                          style: const TextStyle(
                            color: AppTheme.tombstoneWhite,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

