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
  final int skill; // Skill level from 1 to 10 (default: 5)

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
    this.skill = 5,
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
    int? skill,
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
      skill: skill ?? this.skill,
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
      'skill': skill,
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
      skill: (json['skill'] as int?)?.clamp(1, 10) ?? 5,
    );
  }

  factory GamePlayer.fromPlayer(Player player, {PlayerStatus status = PlayerStatus.bench}) {
    return GamePlayer(
      playerId: player.id,
      name: player.name,
      number: player.number,
      status: status,
      skill: player.skill,
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

  /// Computes the Sub-Out urgency score for an on-field player.
  /// Higher score = Higher urgency to substitute OUT.
  /// Formula: 100 * (wShift * Fshift + wTotal * Ftotal + wSkill * Fskill)
  double computeSubOutScore(GamePlayer player) {
    final targetShiftSeconds = (config.subRecommendationMinutes * 60).toDouble();
    final fShift = targetShiftSeconds > 0
        ? player.currentShiftSeconds / targetShiftSeconds
        : 0.0;

    final activePlayers = players.where((p) => !p.isInactive).toList();
    final totalTeamPlayedSeconds = activePlayers.fold<int>(
      0,
      (sum, p) => sum + p.totalPlayedSeconds,
    );
    final avgTotalSeconds = activePlayers.isNotEmpty
        ? totalTeamPlayedSeconds / activePlayers.length
        : targetShiftSeconds;

    final refTotalSeconds = avgTotalSeconds > targetShiftSeconds
        ? avgTotalSeconds
        : targetShiftSeconds;
    final fTotal = refTotalSeconds > 0
        ? player.totalPlayedSeconds / refTotalSeconds
        : 0.0;

    final clampedSkill = player.skill.clamp(1, 10);
    // Neutral at 5.5. Skill 10 => 0.50 factor (stays in longer), Skill 1 => 1.50
    final fSkill = 1.0 - ((clampedSkill - 5.5) / 4.5) * 0.5;

    final weightSum = config.shiftWeight + config.totalTimeWeight + config.skillWeight;
    final double wShift;
    final double wTotal;
    final double wSkill;
    if (weightSum > 0) {
      wShift = config.shiftWeight / weightSum;
      wTotal = config.totalTimeWeight / weightSum;
      wSkill = config.skillWeight / weightSum;
    } else {
      wShift = 0.40;
      wTotal = 0.50;
      wSkill = 0.10;
    }

    return 100.0 * (wShift * fShift + wTotal * fTotal + wSkill * fSkill);
  }

  /// Computes the Sub-In priority score for a bench player.
  /// Higher score = Higher priority to enter the field.
  double computeSubInScore(GamePlayer player) {
    final targetShiftSeconds = (config.subRecommendationMinutes * 60).toDouble();
    final fRest = targetShiftSeconds > 0
        ? player.currentBenchSeconds / targetShiftSeconds
        : 0.0;

    final activePlayers = players.where((p) => !p.isInactive).toList();
    final totalTeamPlayedSeconds = activePlayers.fold<int>(
      0,
      (sum, p) => sum + p.totalPlayedSeconds,
    );
    final avgTotalSeconds = activePlayers.isNotEmpty
        ? totalTeamPlayedSeconds / activePlayers.length
        : targetShiftSeconds;
    final refTotalSeconds = avgTotalSeconds > targetShiftSeconds
        ? avgTotalSeconds
        : targetShiftSeconds;

    final fDeficit = refTotalSeconds > 0
        ? (2.0 - (player.totalPlayedSeconds / refTotalSeconds)).clamp(0.0, 3.0)
        : 1.0;

    final clampedSkill = player.skill.clamp(1, 10);
    final fInSkill = clampedSkill / 5.5;

    final weightSum = config.shiftWeight + config.totalTimeWeight + config.skillWeight;
    final double wShift;
    final double wTotal;
    final double wSkill;
    if (weightSum > 0) {
      wShift = config.shiftWeight / weightSum;
      wTotal = config.totalTimeWeight / weightSum;
      wSkill = config.skillWeight / weightSum;
    } else {
      wShift = 0.40;
      wTotal = 0.50;
      wSkill = 0.10;
    }

    return 100.0 * (wShift * fRest + wTotal * fDeficit + wSkill * fInSkill);
  }

  /// Players currently on the field, sorted by highest SubOutScore first.
  List<GamePlayer> get onFieldPlayers {
    final list = players.where((p) => p.status == PlayerStatus.onField).toList();
    list.sort((a, b) {
      final scoreA = computeSubOutScore(a);
      final scoreB = computeSubOutScore(b);
      final scoreComp = scoreB.compareTo(scoreA);
      if ((scoreB - scoreA).abs() > 0.001) return scoreComp;
      final shiftComp = b.currentShiftSeconds.compareTo(a.currentShiftSeconds);
      if (shiftComp != 0) return shiftComp;
      return b.totalPlayedSeconds.compareTo(a.totalPlayedSeconds);
    });
    return list;
  }

  /// Players currently on the bench, sorted by highest SubInScore first.
  List<GamePlayer> get benchPlayers {
    final list = players.where((p) => p.status == PlayerStatus.bench).toList();
    list.sort((a, b) {
      final scoreA = computeSubInScore(a);
      final scoreB = computeSubInScore(b);
      final scoreComp = scoreB.compareTo(scoreA);
      if ((scoreB - scoreA).abs() > 0.001) return scoreComp;
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
    // Outgoing is the one with highest SubOutScore
    final outgoing = field.first;
    // Incoming is the one on the bench with highest SubInScore
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
