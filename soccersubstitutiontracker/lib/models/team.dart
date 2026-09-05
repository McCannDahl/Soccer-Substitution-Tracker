import 'player.dart';

class Team {
  final String id;
  final String name;
  final List<Player> players;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    required this.players,
    required this.createdAt,
  });

  Team copyWith({
    String? id,
    String? name,
    List<Player>? players,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      players: (json['players'] as List<dynamic>)
          .map((item) => Player.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
