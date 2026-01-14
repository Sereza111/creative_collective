import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/teams_provider.dart';
import 'forms/add_team_screen.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(teamsProvider.notifier).loadTeams());
  }

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('КОМАНДЫ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTeamScreen()),
              );
            },
            tooltip: 'Создать команду',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamsProvider.notifier).loadTeams(),
        backgroundColor: AppTheme.shadowGray,
        color: AppTheme.tombstoneWhite,
        child: teamsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
                ),
              )
            : teamsState.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppTheme.bloodRed),
                          const SizedBox(height: 20),
                          Text(
                            'Ошибка: ${teamsState.error}',
                            style: TextStyle(color: AppTheme.bloodRed),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          AppTheme.gothicButton(
                            text: 'Попробовать снова',
                            onPressed: () => ref.read(teamsProvider.notifier).loadTeams(),
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  )
                : teamsState.teams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_outlined, size: 64, color: AppTheme.mistGray),
                            const SizedBox(height: 20),
                            Text(
                              'Нет команд',
                              style: TextStyle(
                                color: AppTheme.tombstoneWhite,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Создайте первую команду',
                              style: TextStyle(color: AppTheme.mistGray),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: teamsState.teams.length,
                        itemBuilder: (context, index) {
                          final team = teamsState.teams[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AppTheme.slideUpAnimation(
                              offset: 15,
                              duration: Duration(milliseconds: 800 + (index * 100)),
                              child: _buildTeamCard(team),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildTeamCard(team) {
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.tombstoneWhite,
                          letterSpacing: 1.5,
                          fontFamily: 'serif',
                        ),
                      ),
                      if (team.description != null && team.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          team.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mistGray,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dimGray),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${team.membersCount} участников',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mistGray,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            
            // Owner info
            Row(
              children: [
                Text(
                  'ВЛАДЕЛЕЦ:',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.mistGray,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  team.ownerName ?? 'Неизвестно',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.ashGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

