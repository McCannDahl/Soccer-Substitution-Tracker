import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_config.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/team.dart';

class StorageService {
  static const String _teamsKey = 'soccer_teams_v1';
  static const String _configKey = 'soccer_game_config_v1';
  static const String _activeGameKey = 'soccer_active_game_v1';
  static const String _gameHistoryKey = 'soccer_game_history_v1';
  static const String _seededKey = 'soccer_has_seeded_rainbow_fire_v3';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfNeeded();
    return service;
  }

  Future<void> _seedInitialDataIfNeeded() async {
    final hasSeeded = _prefs.getBool(_seededKey) ?? false;
    if (!hasSeeded) {
      final teams = getTeams();
      // Remove placeholder tigers if present
      teams.removeWhere((t) => t.id == 'team_tigers_6u');

      final starterTeam = Team(
        id: 'team_rainbow_fire',
        name: 'Rainbow Fire',
        createdAt: DateTime.now(),
        players: const [
          Player(id: 'p1', name: 'KT', number: 1, skill: 7),
          Player(id: 'p2', name: 'Abi', number: 2, skill: 5),
          Player(id: 'p3', name: 'Melo', number: 3, skill: 8),
          Player(id: 'p4', name: 'Alfredo', number: 4, skill: 5),
          Player(id: 'p5', name: 'Clayton', number: 5, skill: 6),
          Player(id: 'p6', name: 'Daemon', number: 6, skill: 4),
          Player(id: 'p7', name: 'Harrison', number: 7, skill: 7),
          Player(id: 'p8', name: 'Jaxon', number: 8, skill: 5),
          Player(id: 'p9', name: 'Luka', number: 9, skill: 8),
        ],
      );

      final existingIdx = teams.indexWhere((t) => t.id == 'team_rainbow_fire');
      if (existingIdx >= 0) {
        teams[existingIdx] = starterTeam;
      } else {
        teams.insert(0, starterTeam);
      }

      final encoded = teams.map((t) => jsonEncode(t.toJson())).toList();
      await _prefs.setStringList(_teamsKey, encoded);
      await _prefs.setBool(_seededKey, true);
    }
  }

  // --- Teams ---

  List<Team> getTeams() {
    final rawList = _prefs.getStringList(_teamsKey);
    if (rawList == null) return [];
    try {
      return rawList
          .map((item) => Team.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTeam(Team team) async {
    final teams = getTeams();
    final index = teams.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      teams[index] = team;
    } else {
      teams.add(team);
    }
    final encoded = teams.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_teamsKey, encoded);
  }

  Future<void> deleteTeam(String teamId) async {
    final teams = getTeams().where((t) => t.id != teamId).toList();
    final encoded = teams.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_teamsKey, encoded);
  }

  // --- Game Config ---

  GameConfig getGameConfig() {
    final jsonStr = _prefs.getString(_configKey);
    if (jsonStr == null) return const GameConfig();
    try {
      return GameConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return const GameConfig();
    }
  }

  Future<void> saveGameConfig(GameConfig config) async {
    await _prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  // --- Active Game Session ---

  GameSession? getActiveGame() {
    final jsonStr = _prefs.getString(_activeGameKey);
    if (jsonStr == null) return null;
    try {
      return GameSession.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveGame(GameSession session) async {
    await _prefs.setString(_activeGameKey, jsonEncode(session.toJson()));
  }

  Future<void> clearActiveGame() async {
    await _prefs.remove(_activeGameKey);
  }

  // --- Game History ---

  List<GameSession> getGameHistory() {
    final rawList = _prefs.getStringList(_gameHistoryKey);
    if (rawList == null) return [];
    try {
      return rawList
          .map((item) => GameSession.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addGameToHistory(GameSession session) async {
    final history = getGameHistory();
    // Prepend to show most recent first
    history.insert(0, session);
    // Keep last 30 games
    final trimmed = history.take(30).toList();
    final encoded = trimmed.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_gameHistoryKey, encoded);
  }
}
