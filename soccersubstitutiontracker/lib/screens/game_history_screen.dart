import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../services/storage_service.dart';
import '../utils/time_formatter.dart';
import 'game_summary_screen.dart';

class GameHistoryScreen extends StatelessWidget {
  final StorageService storageService;
  final TeamController teamController;
  final GameController gameController;

  const GameHistoryScreen({
    super.key,
    required this.storageService,
    required this.teamController,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final history = storageService.getGameHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Matches'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Match History Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Completed games will appear here with playing time reports.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final session = history[index];
                final dateStr =
                    '${session.startTime.month}/${session.startTime.day}/${session.startTime.year}';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.sports_soccer),
                    ),
                    title: Text(
                      session.teamName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$dateStr • ${TimeFormatter.formatMmSs(session.totalElapsedSeconds)} played • ${session.players.length} players',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameSummaryScreen(
                            session: session,
                            teamController: teamController,
                            gameController: gameController,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
