import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workspace_components.dart';
import 'forms/add_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(projectsProvider.notifier).loadProjects());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateProject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProjectScreen()),
    );
    if (mounted) {
      await ref.read(projectsProvider.notifier).loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsProvider);
    final projects = state.projects.where((project) {
      final matchesStatus =
          _selectedFilter == 'all' || project.status == _selectedFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.description.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проекты'),
        actions: [
          IconButton(
            tooltip: 'Обновить проекты',
            onPressed: () => ref.read(projectsProvider.notifier).loadProjects(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Создать проект',
            onPressed: _openCreateProject,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: WorkspaceContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspacePageIntro(
              eyebrow: 'Рабочий контур',
              title: 'Проекты и ответственность',
              description:
                  'Собирайте этапы, команду и бюджет в едином пространстве.',
              actions: [
                ElevatedButton.icon(
                  onPressed: _openCreateProject,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('Новый проект'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            WorkspaceSearchField(
              controller: _searchController,
              hintText: 'Найти проект по названию или описанию',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(state, 'all', 'Все'),
                _filterChip(state, 'planning', 'Планирование'),
                _filterChip(state, 'active', 'Активные'),
                _filterChip(state, 'completed', 'Завершенные'),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildContent(state, projects)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ProjectsState state, String value, String label) {
    final count = value == 'all'
        ? state.projects.length
        : state.projects.where((project) => project.status == value).length;
    return WorkspaceFilterChip(
      label: label,
      count: count,
      selected: _selectedFilter == value,
      onTap: () => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildContent(ProjectsState state, List<Project> projects) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.projects.isEmpty) {
      return WorkspaceErrorState(
        message: state.error!,
        onRetry: () => ref.read(projectsProvider.notifier).loadProjects(),
      );
    }
    if (projects.isEmpty) {
      final isSearching = _searchQuery.trim().isNotEmpty;
      return WorkspaceEmptyState(
        icon: isSearching ? Icons.search_off : Icons.folder_open_outlined,
        title: isSearching ? 'Ничего не найдено' : 'Проектов пока нет',
        message: isSearching
            ? 'Измените запрос или выберите другую группу.'
            : _selectedFilter == 'all'
                ? 'Создайте первый проект, добавьте сроки и соберите команду.'
                : 'В этой группе проектов пока нет.',
        action: _selectedFilter == 'all' && !isSearching
            ? ElevatedButton.icon(
                onPressed: _openCreateProject,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Создать проект'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
      color: AppTheme.goldenrod,
      backgroundColor: AppTheme.shadowGray,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 620,
          mainAxisExtent: 276,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: projects.length,
        itemBuilder: (_, index) => _ProjectCard(project: projects[index]),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Project project;

  String get _statusLabel => switch (project.status) {
        'planning' => 'Планирование',
        'active' => 'Активен',
        'on_hold' => 'На паузе',
        'completed' => 'Завершен',
        'cancelled' => 'Отменен',
        _ => project.status,
      };

  Color get _statusColor => switch (project.status) {
        'planning' => AppTheme.goldenrod,
        'active' => AppTheme.gothicGreen,
        'on_hold' => AppTheme.deepPurple,
        'completed' => AppTheme.electricBlue,
        'cancelled' => AppTheme.bloodRed,
        _ => AppTheme.ashGray,
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final money = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    final progress = project.progress.clamp(0, 100);

    return WorkspacePanel(
      accent: _statusColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(project: project)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.tombstoneWhite,
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ProjectStatusBadge(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            project.description.isEmpty
                ? 'Описание проекта не добавлено'
                : project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: project.description.isEmpty
                  ? AppTheme.mistGray.withOpacity(0.65)
                  : AppTheme.ashGray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Прогресс',
                style: TextStyle(color: AppTheme.mistGray, fontSize: 11),
              ),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: AppTheme.tombstoneWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 4,
              backgroundColor: AppTheme.dimGray,
              valueColor: AlwaysStoppedAnimation(_statusColor),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _ProjectMeta(
                  label: 'Период',
                  value:
                      '${dateFormat.format(project.startDate)} — ${dateFormat.format(project.endDate)}',
                ),
              ),
              const SizedBox(width: 16),
              _ProjectMeta(
                label: 'Команда',
                value: '${project.teamMembers.length} чел.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProjectMeta(
                  label: 'Бюджет',
                  value: money.format(project.budget),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProjectMeta(
                  label: 'Потрачено',
                  value: money.format(project.spent),
                  valueColor: project.spent > project.budget
                      ? AppTheme.bloodRed
                      : AppTheme.ashGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusBadge extends StatelessWidget {
  const _ProjectStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        border: Border.all(color: color.withOpacity(0.75)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProjectMeta extends StatelessWidget {
  const _ProjectMeta({
    required this.label,
    required this.value,
    this.valueColor = AppTheme.ashGray,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: AppTheme.mistGray, fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: valueColor, fontSize: 11),
        ),
      ],
    );
  }
}
