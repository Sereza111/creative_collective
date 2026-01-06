import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../services/api_service.dart';

// Projects state
class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String? error;

  ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Projects notifier
class ProjectsNotifier extends StateNotifier<ProjectsState> {
  ProjectsNotifier() : super(ProjectsState());

  Future<void> loadProjects({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await ApiService.getProjects(status: status);
      state = ProjectsState(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> createProject(Map<String, dynamic> projectData) async {
    try {
      final newProject = await ApiService.createProject(projectData);
      state = state.copyWith(projects: [...state.projects, newProject]);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> projectData) async {
    try {
      final updatedProject = await ApiService.updateProject(projectId, projectData);
      final updatedProjects = state.projects.map((project) {
        return project.id == projectId ? updatedProject : project;
      }).toList();
      state = state.copyWith(projects: updatedProjects);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await ApiService.deleteProject(projectId);
      final updatedProjects = state.projects.where((project) => project.id != projectId).toList();
      state = state.copyWith(projects: updatedProjects);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier();
});

// Filtered projects providers
final activeProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider).projects;
  return projects.where((project) => project.status == 'active').toList();
});

final planningProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider).projects;
  return projects.where((project) => project.status == 'planning').toList();
});

final completedProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider).projects;
  return projects.where((project) => project.status == 'completed').toList();
});

