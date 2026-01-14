import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../services/api_service.dart';

class TeamsState {
  final List<Team> teams;
  final bool isLoading;
  final String? error;

  TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
  });

  TeamsState copyWith({
    List<Team>? teams,
    bool? isLoading,
    String? error,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TeamsNotifier extends StateNotifier<TeamsState> {
  TeamsNotifier() : super(TeamsState()) {
    loadTeams();
  }

  Future<void> loadTeams() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final teams = await ApiService.getTeams();
      state = TeamsState(teams: teams, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> createTeam(Map<String, dynamic> teamData) async {
    try {
      final newTeam = await ApiService.createTeam(teamData);
      state = state.copyWith(
        teams: [...state.teams, newTeam],
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> updateTeam(int teamId, Map<String, dynamic> teamData) async {
    try {
      final updatedTeam = await ApiService.updateTeam(teamId, teamData);
      state = state.copyWith(
        teams: state.teams.map((team) {
          return team.id == teamId ? updatedTeam : team;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteTeam(int teamId) async {
    try {
      await ApiService.deleteTeam(teamId);
      final updatedTeams = state.teams.where((team) => team.id != teamId).toList();
      state = state.copyWith(teams: updatedTeams);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> addTeamMember(int teamId, int userId, String role) async {
    try {
      await ApiService.addTeamMember(teamId, userId, role);
      await loadTeams(); // Reload to get updated members
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> removeTeamMember(int teamId, int userId) async {
    try {
      await ApiService.removeTeamMember(teamId, userId);
      await loadTeams(); // Reload to get updated members
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

final teamsProvider = StateNotifierProvider<TeamsNotifier, TeamsState>((ref) {
  return TeamsNotifier();
});

