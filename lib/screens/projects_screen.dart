import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ПРОЕКТЫ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Создать проект'),
                  backgroundColor: AppTheme.shadowGray,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTheme.fadeInAnimation(
            child: AppTheme.gothicTitle('Активные'),
          ),
          const SizedBox(height: 32),
          AppTheme.gothicDivider(),
          const SizedBox(height: 32),
          
          AppTheme.slideUpAnimation(
            child: _buildProjectCard(
              context,
              'Видеоклип "Cyberpunk"',
              75,
              '2025-12-20',
              Icons.videocam_outlined,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            duration: const Duration(milliseconds: 900),
            child: _buildProjectCard(
              context,
              'Звуковой дизайн для игры',
              40,
              '2026-01-15',
              Icons.music_note_outlined,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            duration: const Duration(milliseconds: 1000),
            child: _buildProjectCard(
              context,
              '3D модели персонажей',
              60,
              '2025-12-30',
              Icons.view_in_ar_outlined,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            duration: const Duration(milliseconds: 1100),
            child: _buildProjectCard(
              context,
              'Анимация лого',
              90,
              '2025-12-12',
              Icons.animation_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    String title,
    int progress,
    String dueDate,
    IconData icon,
  ) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.dimGray.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(icon, color: AppTheme.ashGray, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.tombstoneWhite,
                          letterSpacing: 1.5,
                          fontFamily: 'serif',
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dueDate,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.mistGray,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            
            // Прогресс
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ПРОГРЕСС',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                    fontFamily: 'serif',
                  ),
                ),
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.ashGray,
                    letterSpacing: 1.0,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Прогресс бар
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppTheme.shadowGray.withOpacity(0.3),
                borderRadius: BorderRadius.zero,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress / 100,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.ashGray,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
