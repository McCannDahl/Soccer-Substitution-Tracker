import 'game_config.dart';
import 'player.dart';

enum PlayerStatus {
  onField,
  bench,
  injured,
  inactive,
}

enum GamePeriodType {
  quarter,
  quarterBreak,
  halftime,
  ended,
}

class GamePlayer {
  final String playerId;
  final String name;
  final int? number;
  final PlayerStatus status;
  final int currentShiftSeconds;
  final int currentBenchSeconds;
  final int totalPlayedSeconds;
  final int totalBenchSeconds;
  final String? injuryNote;

  const GamePlayer({
    required this.playerId,
    required this.name,
    this.number,
    this.status = PlayerStatus.bench,
    this.currentShiftSeconds = 0,
    this.currentBenchSeconds = 0,
    this.totalPlayedSeconds = 0,
    this.totalBenchSeconds = 0,
    this.injuryNote,
  });

  bool get isOnField => status == PlayerStatus.onField;
  bool get isOnBench => status == PlayerStatus.bench;
  bool get isInjured => status == PlayerStatus.injured;
  bool get isInactive => status == PlayerStatus.inactive;

  GamePlayer copyWith({
    String? playerId,
    String? name,
    int? number,
    PlayerStatus? status,
    int? currentShiftSeconds,
    int? currentBenchSeconds,
    int? totalPlayedSeconds,
    int? totalBenchSeconds,
    String? injuryNote,
  }) {
    return GamePlayer(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      number: number ?? this.number,
      status: status ?? this.status,
      currentShiftSeconds: currentShiftSeconds ?? this.currentShiftSeconds,
      currentBenchSeconds: currentBenchSeconds ?? this.currentBenchSeconds,
      totalPlayedSeconds: totalPlayedSeconds ?? this.totalPlayedSeconds,
      totalBenchSeconds: totalBenchSeconds ?? this.totalBenchSeconds,
      injuryNote: injuryNote ?? this.injuryNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'name': name,
      'number': number,
      'status': status.name,
      'currentShiftSeconds': currentShiftSeconds,
      'currentBenchSeconds': currentBenchSeconds,
      'totalPlayedSeconds': totalPlayedSeconds,
      'totalBenchSeconds': totalBenchSeconds,
      'injuryNote': injuryNote,
    };
  }

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      number: json['number'] as int?,
      status: PlayerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PlayerStatus.bench,
      ),
      currentShiftSeconds: json['currentShiftSeconds'] as int? ?? 0,
      currentBenchSeconds: json['currentBenchSeconds'] as int? ?? 0,
      totalPlayedSeconds: json['totalPlayedSeconds'] as int? ?? 0,
      totalBenchSeconds: json['totalBenchSeconds'] as int? ?? 0,
      injuryNote: json['injuryNote'] as String?,
    );
  }

  factory GamePlayer.fromPlayer(Player player, {PlayerStatus status = PlayerStatus.bench}) {
    return GamePlayer(
      playerId: player.id,
      name: player.name,
      number: player.number,
      status: status,
    );
  }
}

class GameEvent {
  final DateTime timestamp;
  final String description;
  final String type;

  const GameEvent({
    required this.timestamp,
    required this.description,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'type': type,
    };
  }

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String,
      type: json['type'] as String,
    );
  }
}

class GameSession {
  final String id;
  final String teamId;
  final String teamName;
  final GameConfig config;
  final int currentPeriod;
  final GamePeriodType periodType;
  final int periodSecondsRemaining;
  final int breakSecondsRemaining;
  final int totalElapsedSeconds;
  final bool isTimerRunning;
  final List<GamePlayer> players;
  final List<GameEvent> events;
  final DateTime startTime;
  final DateTime? endTime;

  const GameSession({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.config,
    this.currentPeriod = 1,
    this.periodType = GamePeriodType.quarter,
    required this.periodSecondsRemaining,
    this.breakSecondsRemaining = 0,
    this.totalElapsedSeconds = 0,
    this.isTimerRunning = false,
    required this.players,
    this.events = const [],
    required this.startTime,
    this.endTime,
  });

  /// Players currently on the field, sorted by who has been playing the longest:
  /// Primary: current shift time DESC
  /// Secondary: total played time DESC
  List<GamePlayer> get onFieldPlayers {
    final list = players.where((p) => p.status == PlayerStatus.onField).toList();
    list.sort((a, b) {
      final shiftComp = b.currentShiftSeconds.compareTo(a.currentShiftSeconds);
      if (shiftComp != 0) return shiftComp;
      return b.totalPlayedSeconds.compareTo(a.totalPlayedSeconds);
    });
    return list;
  }

  /// Players currently on the bench, sorted by who needs to enter the game:
  /// Primary: total played time ASC (least playing time goes in first)
  /// Secondary: current bench rest time DESC (longest rested)
  List<GamePlayer> get benchPlayers {
    final list = players.where((p) => p.status == PlayerStatus.bench).toList();
    list.sort((a, b) {
      final totalComp = a.totalPlayedSeconds.compareTo(b.totalPlayedSeconds);
      if (totalComp != 0) return totalComp;
      return b.currentBenchSeconds.compareTo(a.currentBenchSeconds);
    });
    return list;
  }

  /// Injured or sidelined players
  List<GamePlayer> get injuredPlayers =>
      players.where((p) => p.status == PlayerStatus.injured).toList();

  /// Inactive / left early players
  List<GamePlayer> get inactivePlayers =>
      players.where((p) => p.status == PlayerStatus.inactive).toList();

  /// Recommends a substitution: (outgoing on-field player, incoming bench player)
  (GamePlayer?, GamePlayer?) get recommendedSub {
    final field = onFieldPlayers;
    final bench = benchPlayers;
    if (field.isEmpty || bench.isEmpty) {
      return (null, null);
    }
    // Outgoing is the one who has played the longest this shift
    final outgoing = field.first;
    // Incoming is the one on the bench with the least total playing time
    final incoming = bench.first;
    return (outgoing, incoming);
  }

  bool get isBreak =>
      periodType == GamePeriodType.quarterBreak ||
      periodType == GamePeriodType.halftime;

  bool get isHalftime => periodType == GamePeriodType.halftime;

  bool get isGameOver => periodType == GamePeriodType.ended;

  GameSession copyWith({
    String? id,
    String? teamId,
    String? teamName,
    GameConfig? config,
    int? currentPeriod,
    GamePeriodType? periodType,
    int? periodSecondsRemaining,
    int? breakSecondsRemaining,
    int? totalElapsedSeconds,
    bool? isTimerRunning,
    List<GamePlayer>? players,
    List<GameEvent>? events,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return GameSession(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      config: config ?? this.config,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      periodType: periodType ?? this.periodType,
      periodSecondsRemaining:
          periodSecondsRemaining ?? this.periodSecondsRemaining,
      breakSecondsRemaining:
          breakSecondsRemaining ?? this.breakSecondsRemaining,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      players: players ?? this.players,
      events: events ?? this.events,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'teamName': teamName,
      'config': config.toJson(),
      'currentPeriod': currentPeriod,
      'periodType': periodType.name,
      'periodSecondsRemaining': periodSecondsRemaining,
      'breakSecondsRemaining': breakSecondsRemaining,
      'totalElapsedSeconds': totalElapsedSeconds,
      'isTimerRunning': isTimerRunning,
      'players': players.map((p) => p.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
      currentPeriod: json['currentPeriod'] as int? ?? 1,
      periodType: GamePeriodType.values.firstWhere(
        (e) => e.name == json['periodType'],
        orElse: () => GamePeriodType.quarter,
      ),
      periodSecondsRemaining: json['periodSecondsRemaining'] as int,
      breakSecondsRemaining: json['breakSecondsRemaining'] as int? ?? 0,
      totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
      isTimerRunning: json['isTimerRunning'] as bool? ?? false,
      players: (json['players'] as List<dynamic>)
          .map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      events: ((json['events'] as List<dynamic>?) ?? [])
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }
}
