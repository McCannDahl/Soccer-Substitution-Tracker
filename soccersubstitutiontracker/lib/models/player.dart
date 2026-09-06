class Player {
  final String id;
  final String name;
  final int? number;
  final String? notes;
  final int skill; // Skill level from 1 to 10 (default: 5)

  const Player({
    required this.id,
    required this.name,
    this.number,
    this.notes,
    this.skill = 5,
  });

  Player copyWith({
    String? id,
    String? name,
    int? number,
    String? notes,
    int? skill,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      notes: notes ?? this.notes,
      skill: skill ?? this.skill,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'notes': notes,
      'skill': skill,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as int?,
      notes: json['notes'] as String?,
      skill: (json['skill'] as int?)?.clamp(1, 10) ?? 5,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
