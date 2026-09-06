import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/player.dart';

class MidgamePlayerDialogs {
  /// Dialog to add a late player or guest player mid-game
  static Future<void> showAddPlayerDialog(
    BuildContext context, {
    required List<Player> teamRoster,
    required List<GamePlayer> currentGamePlayers,
    required void Function(Player player, bool toField) onAddPlayer,
  }) async {
    final currentGamePlayerIds =
        currentGamePlayers.map((p) => p.playerId).toSet();
    final absentRosterPlayers = teamRoster
        .where((p) => !currentGamePlayerIds.contains(p.id))
        .toList();

    final nameController = TextEditingController();
    final numberController = TextEditingController();
    bool addToField = false;
    int guestSkill = 5;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.green),
                SizedBox(width: 8),
                Flexible(child: Text('Add Player Mid-Game')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (absentRosterPlayers.isNotEmpty) ...[
                    const Text(
                      'Roster Players (Late Arrivals):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...absentRosterPlayers.map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                p.number != null ? '#${p.number}' : p.name[0],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade400),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 11, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${p.skill}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                onAddPlayer(p, addToField);
                                Navigator.pop(context);
                              },
                              child: const Text('Add'),
                            ),
                          ),
                        )),
                    const Divider(height: 24),
                  ],
                  Text(
                    absentRosterPlayers.isNotEmpty
                        ? 'Or Add Guest / New Player:'
                        : 'Add Guest / New Player:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jersey # (Optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Skill Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              '$guestSkill / 10',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: guestSkill.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$guestSkill',
                    onChanged: (val) => setState(() => guestSkill = val.round()),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    title: const Text('Place Directly on Field', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Default is Bench', style: TextStyle(fontSize: 12)),
                    value: addToField,
                    onChanged: (val) => setState(() => addToField = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final number = int.tryParse(numberController.text.trim());
                  final newPlayer = Player(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    number: number,
                    skill: guestSkill,
                  );
                  onAddPlayer(newPlayer, addToField);
                  Navigator.pop(context);
                },
                child: const Text('Add Player'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog to mark injury with an optional note
  static Future<void> showInjuryDialog(
    BuildContext context, {
    required GamePlayer player,
    required void Function(String? note) onConfirmInjury,
  }) async {
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.healing, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text('Sideline ${player.name}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${player.name} will be marked as injured/sidelined. Their active playing timer will stop.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Reason / Note (Optional)',
                hintText: 'e.g. Scraped knee, resting',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              final note = noteController.text.trim();
              onConfirmInjury(note.isEmpty ? null : note);
              Navigator.pop(context);
            },
            child: const Text('Sideline Player'),
          ),
        ],
      ),
    );
  }

  /// Dialog to manually adjust player's playing time
  static Future<void> showTimeAdjustmentDialog(
    BuildContext context, {
    required GamePlayer player,
    required void Function(int deltaSeconds) onAdjust,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Time: ${player.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quickly correct playing time if a substitution was made earlier without tapping:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('-2 min'),
                  onPressed: () {
                    onAdjust(-120);
                    Navigator.pop(context);
                  },
                ),
                ActionChip(
                  label: const Text('-1 min'),
                  onPressed: () {
                    onAdjust(-60);
                    Navigator.pop(context);
                  },
                ),
                ActionChip(
                  backgroundColor: Colors.green.shade50,
                  label: const Text('+1 min', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onAdjust(60);
                    Navigator.pop(context);
                  },
                ),
                ActionChip(
                  backgroundColor: Colors.green.shade50,
                  label: const Text('+2 min', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onAdjust(120);
                    Navigator.pop(context);
                  },
                ),
                ActionChip(
                  backgroundColor: Colors.green.shade50,
                  label: const Text('+5 min', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onAdjust(300);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
