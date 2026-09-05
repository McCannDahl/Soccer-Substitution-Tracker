import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/time_formatter.dart';

class GameTimerCard extends StatelessWidget {
  final GameSession session;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSkipBreak;
  final void Function(int deltaSeconds) onAdjustTime;

  const GameTimerCard({
    super.key,
    required this.session,
    required this.onTogglePlayPause,
    required this.onSkipBreak,
    required this.onAdjustTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBreak = session.isBreak;
    final isHalftime = session.isHalftime;
    final isRunning = session.isTimerRunning;

    final int displaySeconds =
        isBreak ? session.breakSecondsRemaining : session.periodSecondsRemaining;
    final int maxSeconds = isBreak
        ? (isHalftime
            ? session.config.halftimeMinutes * 60
            : session.config.quarterBreakMinutes * 60)
        : session.config.periodDurationMinutes * 60;

    final double progress = maxSeconds > 0
        ? (1.0 - (displaySeconds / maxSeconds)).clamp(0.0, 1.0)
        : 0.0;

    // Period Title & Badge Color
    String periodTitle;
    Color statusColor;
    IconData statusIcon;

    if (session.periodType == GamePeriodType.quarter) {
      periodTitle = 'Quarter ${session.currentPeriod} of ${session.config.periods}';
      statusColor = isRunning ? Colors.green.shade700 : Colors.amber.shade800;
      statusIcon = isRunning ? Icons.sports_soccer : Icons.pause_circle_outline;
    } else if (session.periodType == GamePeriodType.halftime) {
      periodTitle = 'Halftime Break (${session.config.halftimeMinutes} min)';
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.coffee;
    } else if (session.periodType == GamePeriodType.quarterBreak) {
      periodTitle = 'Quarter Break (${session.config.quarterBreakMinutes} min)';
      statusColor = Colors.teal.shade700;
      statusIcon = Icons.timer;
    } else {
      periodTitle = 'Game Ended';
      statusColor = Colors.blueGrey;
      statusIcon = Icons.flag;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              statusColor.withAlpha(25),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Period Badge & Total Elapsed Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 18, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        periodTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Total: ${TimeFormatter.formatMmSs(session.totalElapsedSeconds)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Timer Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  TimeFormatter.formatMmSs(displaySeconds),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (isBreak) ...[
                  const SizedBox(width: 8),
                  Text(
                    'remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            // Linear Progress Bar
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 16),

            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -1 min button
                IconButton.filledTonal(
                  onPressed: () => onAdjustTime(-60),
                  icon: const Icon(Icons.replay_10),
                  tooltip: '-1 Minute',
                ),
                const SizedBox(width: 12),

                // Big Play / Pause Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isRunning ? Colors.amber.shade800 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onTogglePlayPause,
                  icon: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                  label: Text(
                    isRunning ? 'PAUSE' : 'START',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // +1 min button
                IconButton.filledTonal(
                  onPressed: () => onAdjustTime(60),
                  icon: const Icon(Icons.forward_10),
                  tooltip: '+1 Minute',
                ),

                if (isBreak) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onPressed: onSkipBreak,
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('Skip Break'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
