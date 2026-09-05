import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/storage_service.dart';

class TeamController extends ChangeNotifier {
  final StorageService _storage;
  List<Team> _teams = [];

  TeamController(this._storage) {
    loadTeams();
  }

  List<Team> get teams => List.unmodifiable(_teams);

  void loadTeams() {
    _teams = _storage.getTeams();
    notifyListeners();
  }

  Future<Team> createTeam(String name, [List<Player> initialPlayers = const []]) async {
    final newTeam = Team(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      players: initialPlayers,
      createdAt: DateTime.now(),
    );
    _teams.add(newTeam);
    await _storage.saveTeam(newTeam);
    notifyListeners();
    return newTeam;
  }

  Future<void> updateTeam(Team updatedTeam) async {
    final index = _teams.indexWhere((t) => t.id == updatedTeam.id);
    if (index >= 0) {
      _teams[index] = updatedTeam;
      await _storage.saveTeam(updatedTeam);
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamId) async {
    _teams.removeWhere((t) => t.id == teamId);
    await _storage.deleteTeam(teamId);
    notifyListeners();
  }

  Future<void> addPlayer(String teamId, Player player) async {
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final team = _teams[teamIndex];
      final updatedPlayers = List<Player>.from(team.players)..add(player);
      final updatedTeam = team.copyWith(players: updatedPlayers);
      _teams[teamIndex] = updatedTeam;
      await _storage.saveTeam(updatedTeam);
      notifyListeners();
    }
  }

  Future<void> updatePlayer(String teamId, Player updatedPlayer) async {
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final team = _teams[teamIndex];
      final playerIndex =
          team.players.indexWhere((p) => p.id == updatedPlayer.id);
      if (playerIndex >= 0) {
        final updatedPlayers = List<Player>.from(team.players);
        updatedPlayers[playerIndex] = updatedPlayer;
        final updatedTeam = team.copyWith(players: updatedPlayers);
        _teams[teamIndex] = updatedTeam;
        await _storage.saveTeam(updatedTeam);
        notifyListeners();
      }
    }
  }

  Future<void> removePlayer(String teamId, String playerId) async {
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex >= 0) {
      final team = _teams[teamIndex];
      final updatedPlayers =
          team.players.where((p) => p.id != playerId).toList();
      final updatedTeam = team.copyWith(players: updatedPlayers);
      _teams[teamIndex] = updatedTeam;
      await _storage.saveTeam(updatedTeam);
      notifyListeners();
    }
  }
}
