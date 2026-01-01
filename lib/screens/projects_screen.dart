import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/projects_provider.dart';
import 'forms/add_project_screen.dart';
import 'package:intl/intl.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectsProvider.notifier).loadProjects();
    });
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'planning':
        return 'Планирование';
      case 'active':
        return 'Активен';
      case 'on_hold':
        return 'Приостановлен';
      case 'completed':
        return 'Завершен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planning':
        return AppTheme.mistGray;
      case 'active':
        return AppTheme.ashGray;
      case 'on_hold':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return AppTheme.bloodRed;
      default:
        return AppTheme.mistGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    
    // Filter projects based on selected filter
    final filteredProjects = _selectedFilter == 'all'
        ? projectsState.projects
        : projectsState.projects.where((project) => project.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ПРОЕКТЫ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(projectsProvider.notifier).loadProjects();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProjectScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Все'),
                const SizedBox(width: 10),
                _buildFilterChip('planning', 'Планирование'),
                const SizedBox(width: 10),
                _buildFilterChip('active', 'Активные'),
                const SizedBox(width: 10),
                _buildFilterChip('completed', 'Завершенные'),
              ],
            ),
          ),
          
          Expanded(
            child: projectsState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.tombstoneWhite,
                      ),
                    ),
                  )
                : projectsState.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.bloodRed,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Ошибка загрузки проектов',
                                style: TextStyle(
                                  color: AppTheme.tombstoneWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                projectsState.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.mistGray,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppTheme.gothicButton(
                                text: 'Повторить',
                                onPressed: () {
                                  ref.read(projectsProvider.notifier).loadProjects();
                                },
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredProjects.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 64,
                                    color: AppTheme.mistGray,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Нет проектов',
                                    style: TextStyle(
                                      color: AppTheme.tombstoneWhite,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _selectedFilter == 'all'
                                        ? 'Создайте первый проект'
                                        : 'Нет проектов с выбранным статусом',
                                    style: TextStyle(
                                      color: AppTheme.mistGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(projectsProvider.notifier).loadProjects();
                            },
                            backgroundColor: AppTheme.shadowGray,
                            color: AppTheme.tombstoneWhite,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredProjects.length,
                              itemBuilder: (context, index) {
                                final project = filteredProjects[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: AppTheme.slideUpAnimation(
                                    offset: 15,
                                    duration: Duration(
                                      milliseconds: 800 + (index * 100),
                                    ),
                                    child: _buildProjectCard(context, project),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.tombstoneWhite : AppTheme.shadowGray,
          border: Border.all(
            color: isSelected ? AppTheme.tombstoneWhite : AppTheme.dimGray,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.voidBlack : AppTheme.mistGray,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, project) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final budgetFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    
    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.tombstoneWhite,
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _getStatusColor(project.status),
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    _getStatusText(project.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: _getStatusColor(project.status),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mistGray,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppTheme.dimGray.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      '${project.progress}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.ashGray,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.shadowGray.withOpacity(0.3),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: project.progress / 100,
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
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Дата начала', 
                  dateFormat.format(project.startDate),
                ),
                _buildInfoItem(
                  'Дата окончания', 
                  dateFormat.format(project.endDate),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Бюджет', 
                  budgetFormat.format(project.budget),
                ),
                _buildInfoItem(
                  'Потрачено', 
                  budgetFormat.format(project.spent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: AppTheme.mistGray,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: AppTheme.ashGray,
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }
}
