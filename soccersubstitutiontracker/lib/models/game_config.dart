class GameConfig {
  /// Number of game periods (default 4 quarters).
  final int periods;

  /// Duration of each quarter in minutes (default 10).
  final int periodDurationMinutes;

  /// Break between Q1 & Q2, and between Q3 & Q4 in minutes (default 2).
  final int quarterBreakMinutes;

  /// Break at halftime (between Q2 & Q3) in minutes (default 4).
  final int halftimeMinutes;

  /// Number of players on the field at one time (default 4 for 6U).
  final int playersOnField;

  /// Recommended shift length in minutes before suggesting a sub (default 5).
  final int subRecommendationMinutes;

  /// Whether sound notifications should play on breaks/subs.
  final bool soundEnabled;

  /// Whether vibration/haptic feedback is enabled.
  final bool vibrationEnabled;

  const GameConfig({
    this.periods = 4,
    this.periodDurationMinutes = 10,
    this.quarterBreakMinutes = 2,
    this.halftimeMinutes = 4,
    this.playersOnField = 4,
    this.subRecommendationMinutes = 5,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  GameConfig copyWith({
    int? periods,
    int? periodDurationMinutes,
    int? quarterBreakMinutes,
    int? halftimeMinutes,
    int? playersOnField,
    int? subRecommendationMinutes,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return GameConfig(
      periods: periods ?? this.periods,
      periodDurationMinutes:
          periodDurationMinutes ?? this.periodDurationMinutes,
      quarterBreakMinutes: quarterBreakMinutes ?? this.quarterBreakMinutes,
      halftimeMinutes: halftimeMinutes ?? this.halftimeMinutes,
      playersOnField: playersOnField ?? this.playersOnField,
      subRecommendationMinutes:
          subRecommendationMinutes ?? this.subRecommendationMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periods': periods,
      'periodDurationMinutes': periodDurationMinutes,
      'quarterBreakMinutes': quarterBreakMinutes,
      'halftimeMinutes': halftimeMinutes,
      'playersOnField': playersOnField,
      'subRecommendationMinutes': subRecommendationMinutes,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      periods: json['periods'] as int? ?? 4,
      periodDurationMinutes: json['periodDurationMinutes'] as int? ?? 10,
      quarterBreakMinutes: json['quarterBreakMinutes'] as int? ?? 2,
      halftimeMinutes: json['halftimeMinutes'] as int? ?? 4,
      playersOnField: json['playersOnField'] as int? ?? 4,
      subRecommendationMinutes:
          json['subRecommendationMinutes'] as int? ?? 5,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    );
  }
}
