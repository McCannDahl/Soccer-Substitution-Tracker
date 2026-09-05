import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/alert_service.dart';
import '../services/storage_service.dart';

class GameController extends ChangeNotifier {
  final StorageService _storage;
  GameSession? _session;
  Timer? _timer;

  VoidCallback? onPeriodEnded;
  VoidCallback? onBreakEnded;
  VoidCallback? onSubAlert;

  GameController(this._storage) {
    _loadActiveGame();
  }

  GameSession? get session => _session;
  bool get hasActiveGame => _session != null && !_session!.isGameOver;
  bool get isTimerRunning => _session?.isTimerRunning ?? false;
  StorageService get storage => _storage;

  void _loadActiveGame() {
    _session = _storage.getActiveGame();
    if (_session != null && _session!.isTimerRunning) {
      // Pause on restore so it doesn't run unexpectedly in the background
      _session = _session!.copyWith(isTimerRunning: false);
      _storage.saveActiveGame(_session!);
    }
    notifyListeners();
  }

  void startGame({
    required Team team,
    required List<Player> attendingPlayers,
    required List<String> startingFieldPlayerIds,
    required GameConfig config,
  }) {
    _timer?.cancel();

    final gamePlayers = attendingPlayers.map((p) {
      final isStarting = startingFieldPlayerIds.contains(p.id);
      return GamePlayer.fromPlayer(
        p,
        status: isStarting ? PlayerStatus.onField : PlayerStatus.bench,
      );
    }).toList();

    final initialEvent = GameEvent(
      timestamp: DateTime.now(),
      description: 'Game started: Quarter 1 of ${config.periods}',
      type: 'quarter_start',
    );

    _session = GameSession(
      id: 'game_${DateTime.now().millisecondsSinceEpoch}',
      teamId: team.id,
      teamName: team.name,
      config: config,
      currentPeriod: 1,
      periodType: GamePeriodType.quarter,
      periodSecondsRemaining: config.periodDurationMinutes * 60,
      breakSecondsRemaining: 0,
      totalElapsedSeconds: 0,
      isTimerRunning: true,
      players: gamePlayers,
      events: [initialEvent],
      startTime: DateTime.now(),
    );

    _storage.saveActiveGame(_session!);
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_session == null || !_session!.isTimerRunning) return;

    if (_session!.periodType == GamePeriodType.quarter) {
      _tickQuarter();
    } else if (_session!.isBreak) {
      _tickBreak();
    }
  }

  void _tickQuarter() {
    final s = _session!;
    final newRemaining = s.periodSecondsRemaining - 1;
    final newTotalElapsed = s.totalElapsedSeconds + 1;

    // Update player timers
    final updatedPlayers = s.players.map((p) {
      if (p.status == PlayerStatus.onField) {
        return p.copyWith(
          currentShiftSeconds: p.currentShiftSeconds + 1,
          totalPlayedSeconds: p.totalPlayedSeconds + 1,
        );
      } else if (p.status == PlayerStatus.bench) {
        return p.copyWith(
          currentBenchSeconds: p.currentBenchSeconds + 1,
          totalBenchSeconds: p.totalBenchSeconds + 1,
        );
      }
      return p;
    }).toList();

    if (newRemaining <= 0) {
      // Period has ended!
      _handleQuarterEnded(updatedPlayers, newTotalElapsed);
    } else {
      _session = s.copyWith(
        periodSecondsRemaining: newRemaining,
        totalElapsedSeconds: newTotalElapsed,
        players: updatedPlayers,
      );
      _storage.saveActiveGame(_session!);
      notifyListeners();
    }
  }

  void _handleQuarterEnded(List<GamePlayer> updatedPlayers, int totalElapsed) {
    final s = _session!;
    _timer?.cancel();

    AlertService.notifyPeriodEnd(
      sound: s.config.soundEnabled,
      vibration: s.config.vibrationEnabled,
    );

    final isHalftimePeriod = s.currentPeriod == (s.config.periods / 2).ceil();
    final isFinalPeriod = s.currentPeriod >= s.config.periods;

    if (isFinalPeriod) {
      // Game ended!
      final endEvent = GameEvent(
        timestamp: DateTime.now(),
        description: 'Final whistle! Game ended.',
        type: 'game_end',
      );
      _session = s.copyWith(
        periodSecondsRemaining: 0,
        totalElapsedSeconds: totalElapsed,
        isTimerRunning: false,
        periodType: GamePeriodType.ended,
        players: updatedPlayers,
        events: [...s.events, endEvent],
        endTime: DateTime.now(),
      );
      _storage.addGameToHistory(_session!);
      _storage.clearActiveGame();
    } else if (isHalftimePeriod) {
      // Halftime break
      final breakEvent = GameEvent(
        timestamp: DateTime.now(),
        description: 'Quarter ${s.currentPeriod} finished. Halftime break started.',
        type: 'halftime_start',
      );
      _session = s.copyWith(
        periodSecondsRemaining: 0,
        totalElapsedSeconds: totalElapsed,
        isTimerRunning: true,
        periodType: GamePeriodType.halftime,
        breakSecondsRemaining: s.config.halftimeMinutes * 60,
        players: updatedPlayers,
        events: [...s.events, breakEvent],
      );
      _storage.saveActiveGame(_session!);
      _startTicker();
    } else {
      // Quarter break
      final breakEvent = GameEvent(
        timestamp: DateTime.now(),
        description:
            'Quarter ${s.currentPeriod} finished. ${s.config.quarterBreakMinutes}-min break started.',
        type: 'break_start',
      );
      _session = s.copyWith(
        periodSecondsRemaining: 0,
        totalElapsedSeconds: totalElapsed,
        isTimerRunning: true,
        periodType: GamePeriodType.quarterBreak,
        breakSecondsRemaining: s.config.quarterBreakMinutes * 60,
        players: updatedPlayers,
        events: [...s.events, breakEvent],
      );
      _storage.saveActiveGame(_session!);
      _startTicker();
    }

    onPeriodEnded?.call();
    notifyListeners();
  }

  void _tickBreak() {
    final s = _session!;
    final newBreakRemaining = s.breakSecondsRemaining - 1;

    if (newBreakRemaining <= 0) {
      // Break has ended!
      _handleBreakEnded();
    } else {
      _session = s.copyWith(
        breakSecondsRemaining: newBreakRemaining,
      );
      _storage.saveActiveGame(_session!);
      notifyListeners();
    }
  }

  void _handleBreakEnded() {
    final s = _session!;
    _timer?.cancel();

    AlertService.notifyBreakEnd(
      sound: s.config.soundEnabled,
      vibration: s.config.vibrationEnabled,
    );

    final nextPeriod = s.currentPeriod + 1;
    final nextEvent = GameEvent(
      timestamp: DateTime.now(),
      description: 'Break ended. Ready for Quarter $nextPeriod.',
      type: 'break_end',
    );

    // Pause timer so coach manually kicks off the next quarter
    _session = s.copyWith(
      currentPeriod: nextPeriod,
      periodType: GamePeriodType.quarter,
      periodSecondsRemaining: s.config.periodDurationMinutes * 60,
      breakSecondsRemaining: 0,
      isTimerRunning: false,
      events: [...s.events, nextEvent],
    );

    _storage.saveActiveGame(_session!);
    onBreakEnded?.call();
    notifyListeners();
  }

  // --- Timer Controls ---

  void toggleTimer() {
    if (_session == null || _session!.isGameOver) return;
    AlertService.buttonTapFeedback();

    if (_session!.isTimerRunning) {
      pauseTimer();
    } else {
      resumeTimer();
    }
  }

  void pauseTimer() {
    if (_session == null) return;
    _timer?.cancel();
    _session = _session!.copyWith(isTimerRunning: false);
    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void resumeTimer() {
    if (_session == null || _session!.isGameOver) return;
    _session = _session!.copyWith(isTimerRunning: true);
    _storage.saveActiveGame(_session!);
    _startTicker();
    notifyListeners();
  }

  void skipBreak() {
    if (_session == null || !_session!.isBreak) return;
    AlertService.buttonTapFeedback();
    _handleBreakEnded();
  }

  void adjustGameTime(int deltaSeconds) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    if (_session!.periodType == GamePeriodType.quarter) {
      final updated = (_session!.periodSecondsRemaining + deltaSeconds).clamp(0, 3600);
      _session = _session!.copyWith(periodSecondsRemaining: updated);
    } else if (_session!.isBreak) {
      final updated = (_session!.breakSecondsRemaining + deltaSeconds).clamp(0, 3600);
      _session = _session!.copyWith(breakSecondsRemaining: updated);
    }
    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  // --- Player Substitution & Toggling ---

  /// Toggles player between onField and bench.
  void togglePlayerStatus(String playerId) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final playerIndex =
        _session!.players.indexWhere((p) => p.playerId == playerId);
    if (playerIndex < 0) return;

    final player = _session!.players[playerIndex];
    PlayerStatus newStatus;
    int newShift = player.currentShiftSeconds;
    int newBench = player.currentBenchSeconds;
    String eventDesc;

    if (player.status == PlayerStatus.onField) {
      newStatus = PlayerStatus.bench;
      newShift = 0; // reset shift timer
      newBench = 0; // reset bench timer
      eventDesc = '${player.name} moved to Bench';
    } else if (player.status == PlayerStatus.bench) {
      newStatus = PlayerStatus.onField;
      newShift = 0; // reset shift timer
      newBench = 0; // reset bench timer
      eventDesc = '${player.name} moved onto Field';
    } else {
      // If injured or inactive, do not toggle blindly
      return;
    }

    final updatedPlayer = player.copyWith(
      status: newStatus,
      currentShiftSeconds: newShift,
      currentBenchSeconds: newBench,
    );

    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    final subEvent = GameEvent(
      timestamp: DateTime.now(),
      description: eventDesc,
      type: 'sub',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, subEvent],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  /// One-tap substitution: Outgoing to Bench, Incoming to Field
  void executeSub(String outgoingPlayerId, String incomingPlayerId) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final outIdx =
        _session!.players.indexWhere((p) => p.playerId == outgoingPlayerId);
    final inIdx =
        _session!.players.indexWhere((p) => p.playerId == incomingPlayerId);

    if (outIdx < 0 || inIdx < 0) return;

    final outPlayer = _session!.players[outIdx];
    final inPlayer = _session!.players[inIdx];

    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[outIdx] = outPlayer.copyWith(
      status: PlayerStatus.bench,
      currentShiftSeconds: 0,
      currentBenchSeconds: 0,
    );
    updatedPlayers[inIdx] = inPlayer.copyWith(
      status: PlayerStatus.onField,
      currentShiftSeconds: 0,
      currentBenchSeconds: 0,
    );

    final subEvent = GameEvent(
      timestamp: DateTime.now(),
      description: 'Sub: ${outPlayer.name} OUT, ${inPlayer.name} IN',
      type: 'sub',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, subEvent],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  // --- Injury & Mid-Game Roster Management ---

  void markPlayerInjured(String playerId, {String? note}) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final idx = _session!.players.indexWhere((p) => p.playerId == playerId);
    if (idx < 0) return;

    final player = _session!.players[idx];
    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[idx] = player.copyWith(
      status: PlayerStatus.injured,
      injuryNote: note,
      currentShiftSeconds: 0,
    );

    final injuryEvent = GameEvent(
      timestamp: DateTime.now(),
      description: '${player.name} sidelined due to injury${note != null ? " ($note)" : ""}',
      type: 'injury',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, injuryEvent],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void returnPlayerFromInjury(String playerId) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final idx = _session!.players.indexWhere((p) => p.playerId == playerId);
    if (idx < 0) return;

    final player = _session!.players[idx];
    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[idx] = player.copyWith(
      status: PlayerStatus.bench,
      injuryNote: null,
      currentBenchSeconds: 0,
    );

    final returnEvent = GameEvent(
      timestamp: DateTime.now(),
      description: '${player.name} recovered and returned to Bench',
      type: 'return',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, returnEvent],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void removePlayerFromGame(String playerId) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final idx = _session!.players.indexWhere((p) => p.playerId == playerId);
    if (idx < 0) return;

    final player = _session!.players[idx];
    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[idx] = player.copyWith(
      status: PlayerStatus.inactive,
      currentShiftSeconds: 0,
    );

    final event = GameEvent(
      timestamp: DateTime.now(),
      description: '${player.name} left the game',
      type: 'remove',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, event],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void addPlayerToGame(Player player, {bool toField = false}) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    // Avoid duplicate player id
    final existingIdx =
        _session!.players.indexWhere((p) => p.playerId == player.id);
    if (existingIdx >= 0) {
      // Re-activate if was inactive
      final existing = _session!.players[existingIdx];
      final updatedPlayers = List<GamePlayer>.from(_session!.players);
      updatedPlayers[existingIdx] = existing.copyWith(
        status: toField ? PlayerStatus.onField : PlayerStatus.bench,
      );
      _session = _session!.copyWith(players: updatedPlayers);
      _storage.saveActiveGame(_session!);
      notifyListeners();
      return;
    }

    final newGamePlayer = GamePlayer.fromPlayer(
      player,
      status: toField ? PlayerStatus.onField : PlayerStatus.bench,
    );

    final event = GameEvent(
      timestamp: DateTime.now(),
      description:
          '${player.name} joined mid-game (${toField ? "On Field" : "On Bench"})',
      type: 'add_player',
    );

    _session = _session!.copyWith(
      players: [..._session!.players, newGamePlayer],
      events: [..._session!.events, event],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void adjustPlayerTime(String playerId, int deltaSeconds) {
    if (_session == null) return;
    AlertService.buttonTapFeedback();

    final idx = _session!.players.indexWhere((p) => p.playerId == playerId);
    if (idx < 0) return;

    final player = _session!.players[idx];
    final newTotal = (player.totalPlayedSeconds + deltaSeconds).clamp(0, 7200);
    final newShift = (player.currentShiftSeconds + deltaSeconds).clamp(0, 3600);

    final updatedPlayers = List<GamePlayer>.from(_session!.players);
    updatedPlayers[idx] = player.copyWith(
      totalPlayedSeconds: newTotal,
      currentShiftSeconds: newShift,
    );

    final event = GameEvent(
      timestamp: DateTime.now(),
      description:
          'Adjusted ${player.name} playing time by ${deltaSeconds > 0 ? "+" : ""}${deltaSeconds ~/ 60}m',
      type: 'time_adjust',
    );

    _session = _session!.copyWith(
      players: updatedPlayers,
      events: [..._session!.events, event],
    );

    _storage.saveActiveGame(_session!);
    notifyListeners();
  }

  void endGame() {
    if (_session == null) return;
    _timer?.cancel();
    AlertService.buttonTapFeedback();

    final endEvent = GameEvent(
      timestamp: DateTime.now(),
      description: 'Game ended by coach.',
      type: 'game_end',
    );

    _session = _session!.copyWith(
      isTimerRunning: false,
      periodType: GamePeriodType.ended,
      events: [..._session!.events, endEvent],
      endTime: DateTime.now(),
    );

    _storage.addGameToHistory(_session!);
    _storage.clearActiveGame();
    notifyListeners();
  }

  void cancelActiveGame() {
    _timer?.cancel();
    _session = null;
    _storage.clearActiveGame();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
