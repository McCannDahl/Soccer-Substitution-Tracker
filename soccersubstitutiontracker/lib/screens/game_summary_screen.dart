import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../models/game_session.dart';
import '../utils/time_formatter.dart';

class GameSummaryScreen extends StatelessWidget {
  final GameSession session;
  final TeamController teamController;
  final GameController gameController;

  const GameSummaryScreen({
    super.key,
    required this.session,
    required this.teamController,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGameSeconds = session.totalElapsedSeconds > 0
        ? session.totalElapsedSeconds
        : 1;

    // Sort players by total played time descending for report
    final sortedPlayers = List<GamePlayer>.from(session.players)
      ..sort((a, b) => b.totalPlayedSeconds.compareTo(a.totalPlayedSeconds));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Report & Playing Time'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celebratory Final Whistle Header
            Card(
              color: Colors.green.shade800,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      'MATCH COMPLETED',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.teamName,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          backgroundColor: Colors.white12,
                          label: Text(
                            'Duration: ${TimeFormatter.formatMmSs(session.totalElapsedSeconds)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        Chip(
                          backgroundColor: Colors.white12,
                          label: Text(
                            'Quarters: ${session.currentPeriod} of ${session.config.periods}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        Chip(
                          backgroundColor: Colors.white12,
                          label: Text(
                            'Format: ${session.config.playersOnField}v${session.config.playersOnField}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Equal Playing Time Analysis Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Player Playing Time Distribution',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.balance, size: 20, color: Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '6U soccer goal: ensure equal or near-equal field time for every player.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),

            // Player Breakdown Cards
            ...sortedPlayers.map((player) {
              final double percentOfGame =
                  ((player.totalPlayedSeconds / totalGameSeconds) * 100).clamp(0, 100);
              final double progressRatio =
                  (player.totalPlayedSeconds / totalGameSeconds).clamp(0.0, 1.0);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            child: Text(
                              player.number != null ? '#${player.number}' : player.name[0],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Text(
                            TimeFormatter.formatShort(player.totalPlayedSeconds),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${percentOfGame.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentOfGame > 60
                                ? Colors.green.shade700
                                : (percentOfGame >= 30 ? Colors.teal : Colors.amber.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Match Timeline / Events
            if (session.events.isNotEmpty) ...[
              ExpansionTile(
                title: const Text('Match Timeline & Events', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${session.events.length} recorded events'),
                children: session.events.reversed.map((e) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 16),
                    title: Text(e.description, style: const TextStyle(fontSize: 13)),
                    trailing: Text(
                      TimeFormatter.formatMmSs(
                        e.timestamp.difference(session.startTime).inSeconds.clamp(0, 7200),
                      ),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Done Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'DONE & RETURN HOME',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
