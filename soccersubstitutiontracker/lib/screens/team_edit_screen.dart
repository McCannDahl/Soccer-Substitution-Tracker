import 'package:flutter/material.dart';
import '../controllers/team_controller.dart';
import '../models/player.dart';
import '../models/team.dart';

class TeamEditScreen extends StatefulWidget {
  final TeamController teamController;
  final Team? existingTeam;

  const TeamEditScreen({
    super.key,
    required this.teamController,
    this.existingTeam,
  });

  @override
  State<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends State<TeamEditScreen> {
  late final TextEditingController _nameController;
  late List<Player> _players;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingTeam?.name ?? '');
    _players = widget.existingTeam != null
        ? List<Player>.from(widget.existingTeam!.players)
        : [
            const Player(id: 'p_1', name: 'Leo', number: 7),
            const Player(id: 'p_2', name: 'Maya', number: 10),
            const Player(id: 'p_3', name: 'Noah', number: 4),
            const Player(id: 'p_4', name: 'Emma', number: 9),
            const Player(id: 'p_5', name: 'Liam', number: 11),
            const Player(id: 'p_6', name: 'Ava', number: 3),
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddPlayerDialog([Player? existingPlayer, int? index]) {
    final playerNameController =
        TextEditingController(text: existingPlayer?.name ?? '');
    final playerNumberController =
        TextEditingController(text: existingPlayer?.number?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingPlayer == null ? 'Add Player' : 'Edit Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: playerNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: playerNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jersey # (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = playerNameController.text.trim();
              if (name.isEmpty) return;
              final number = int.tryParse(playerNumberController.text.trim());

              setState(() {
                if (existingPlayer != null && index != null) {
                  _players[index] = existingPlayer.copyWith(name: name, number: number);
                } else {
                  _players.add(
                    Player(
                      id: 'p_${DateTime.now().millisecondsSinceEpoch}_${_players.length}',
                      name: name,
                      number: number,
                    ),
                  );
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a team name')),
      );
      return;
    }
    if (_players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one player')),
      );
      return;
    }

    if (widget.existingTeam != null) {
      final updated = widget.existingTeam!.copyWith(
        name: name,
        players: _players,
      );
      await widget.teamController.updateTeam(updated);
    } else {
      await widget.teamController.createTeam(name, _players);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTeam == null ? 'Create Team' : 'Edit Team'),
        actions: [
          TextButton.icon(
            onPressed: _saveTeam,
            icon: const Icon(Icons.check),
            label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name (e.g. Rainbow Fire)',
                prefixIcon: Icon(Icons.shield_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Players Roster (${_players.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddPlayerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Player'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_players.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No players added yet. Tap "Add Player" to build your roster.'),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _players.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _players.removeAt(oldIndex);
                    _players.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return Card(
                    key: ValueKey(player.id),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        child: Text(
                          player.number != null ? '#${player.number}' : player.name[0],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: player.number != null ? Text('Jersey #${player.number}') : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showAddPlayerDialog(player, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _players.removeAt(index);
                              });
                            },
                          ),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
