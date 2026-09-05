import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../services/storage_service.dart';
import '../utils/time_formatter.dart';
import 'active_game_screen.dart';
import 'game_history_screen.dart';
import 'game_setup_screen.dart';
import 'team_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storageService;
  final TeamController teamController;
  final GameController gameController;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.teamController,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.green),
            SizedBox(width: 8),
            Text('Sub Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Game History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameHistoryScreen(
                    storageService: storageService,
                    teamController: teamController,
                    gameController: gameController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: gameController,
        builder: (context, _) {
          final hasActiveGame = gameController.hasActiveGame;
          final session = gameController.session;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Game in Progress Banner (if any)
                if (hasActiveGame && session != null) ...[
                  Card(
                    color: Colors.green.shade900,
                    elevation: 4,
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
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.lightGreenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'GAME IN PROGRESS',
                                style: TextStyle(
                                  color: Colors.lightGreenAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Q${session.currentPeriod} of ${session.config.periods}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session.teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.isBreak
                                ? 'Break: ${TimeFormatter.formatMmSs(session.breakSecondsRemaining)} remaining'
                                : 'Quarter Clock: ${TimeFormatter.formatMmSs(session.periodSecondsRemaining)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActiveGameScreen(
                                    gameController: gameController,
                                    teamController: teamController,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text(
                              'RESUME ACTIVE GAME',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hero Start Game Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameSetupScreen(
                            teamController: teamController,
                            gameController: gameController,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade900,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start a Game',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select lineup, track timers & sub recommendations',
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Manage Teams Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal.shade800,
                      child: const Icon(Icons.groups),
                    ),
                    title: const Text(
                      'Manage Teams & Rosters',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: ListenableBuilder(
                      listenable: teamController,
                      builder: (context, _) {
                        final count = teamController.teams.length;
                        return Text('$count team${count == 1 ? "" : "s"} configured');
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamListScreen(
                            teamController: teamController,
                            gameController: gameController,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Past Games History Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      child: const Icon(Icons.assessment_outlined),
                    ),
                    title: const Text(
                      'Match Reports & History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text('Review past playing time distribution'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameHistoryScreen(
                            storageService: storageService,
                            teamController: teamController,
                            gameController: gameController,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 6U Soccer Coach Guide Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
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
                            Icon(Icons.info_outline, size: 20, color: Colors.green.shade800),
                            const SizedBox(width: 8),
                            const Text(
                              'Default 6U Match Rules',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '• 4 Quarters of 10 minutes\n'
                          '• 2-minute quarter breaks & 4-minute halftime\n'
                          '• 4 on 4 format\n'
                          '• Tap any player to sub in/out anytime\n'
                          '• Sidelined/injured players can be managed mid-game',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
