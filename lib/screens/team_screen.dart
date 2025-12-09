import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('КОМАНДА'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавить члена команды'),
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
            child: AppTheme.gothicTitle('Участники'),
          ),
          const SizedBox(height: 32),
          AppTheme.gothicDivider(),
          const SizedBox(height: 32),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            child: _buildTeamMember(
              context,
              'Денис',
              'Программист',
              'Full Stack Developer',
              ['Flutter', 'React', 'Node.js'],
              true,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 900),
            child: _buildTeamMember(
              context,
              'Иван',
              'Битмейкер',
              'Music Producer',
              ['FL Studio', 'Ableton', 'Logic Pro'],
              true,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 1000),
            child: _buildTeamMember(
              context,
              'Мария',
              'Дизайнер',
              'UI/UX Designer',
              ['Figma', 'Photoshop', 'Illustrator'],
              true,
            ),
          ),
          const SizedBox(height: 16),
          
          AppTheme.slideUpAnimation(
            offset: 15,
            duration: const Duration(milliseconds: 1100),
            child: _buildTeamMember(
              context,
              'Алексей',
              'Монтажер',
              'Video Editor',
              ['Premiere Pro', 'After Effects'],
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(
    BuildContext context,
    String name,
    String role,
    String subtitle,
    List<String> skills,
    bool isAvailable,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.dimGray.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.ashGray,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.tombstoneWhite,
                          letterSpacing: 2.5,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.ashGray,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.mistGray,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTheme.gothicBadge(
                  isAvailable ? 'Свободен' : 'Занят',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            
            // Навыки
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'НАВЫКИ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.dimGray.withOpacity(0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        skill.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.ashGray,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
