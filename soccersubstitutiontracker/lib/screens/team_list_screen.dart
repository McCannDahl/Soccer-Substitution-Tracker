import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../models/team.dart';
import 'game_setup_screen.dart';
import 'team_edit_screen.dart';

class TeamListScreen extends StatelessWidget {
  final TeamController teamController;
  final GameController gameController;

  const TeamListScreen({
    super.key,
    required this.teamController,
    required this.gameController,
  });

  void _confirmDeleteTeam(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${team.name}?'),
        content: const Text('Are you sure you want to remove this team? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              teamController.deleteTeam(team.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
      ),
      body: ListenableBuilder(
        listenable: teamController,
        builder: (context, _) {
          final teams = teamController.teams;
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Teams Created Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first team to track substitutions'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TeamEditScreen(teamController: teamController),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Team'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.green.shade800,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.shield, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${team.players.length} Players on Roster',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Roster',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamEditScreen(
                                    teamController: teamController,
                                    existingTeam: team,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Team',
                            onPressed: () => _confirmDeleteTeam(context, team),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Roster preview chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: team.players.take(8).map((p) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            avatar: CircleAvatar(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              child: Text(
                                p.number != null ? '${p.number}' : p.name[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            label: Text(p.name, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameSetupScreen(
                                    teamController: teamController,
                                    gameController: gameController,
                                    preselectedTeam: team,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sports_soccer, size: 18),
                            label: const Text('Start Game With Team'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TeamEditScreen(teamController: teamController),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
      ),
    );
  }
}
