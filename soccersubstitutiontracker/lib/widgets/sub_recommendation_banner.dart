import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/time_formatter.dart';

class SubRecommendationBanner extends StatelessWidget {
  final GameSession session;
  final void Function(String outgoingId, String incomingId) onExecuteSub;

  const SubRecommendationBanner({
    super.key,
    required this.session,
    required this.onExecuteSub,
  });

  @override
  Widget build(BuildContext context) {
    final (outgoing, incoming) = session.recommendedSub;
    if (outgoing == null || incoming == null) {
      return const SizedBox.shrink();
    }

    final isUrgent = outgoing.currentShiftSeconds >=
        (session.config.subRecommendationMinutes * 60);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.amber.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? Colors.amber.shade700 : Colors.blue.shade300,
          width: isUrgent ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.notification_important : Icons.swap_horiz,
            color: isUrgent ? Colors.amber.shade900 : Colors.blue.shade800,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? 'SUB RECOMMENDED (Shift Target Hit)' : 'Next Rotation Suggestion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? Colors.amber.shade900 : Colors.blue.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      const TextSpan(text: 'OUT: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      TextSpan(
                        text: '${outgoing.name} (${TimeFormatter.formatMmSs(outgoing.currentShiftSeconds)})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '  ➔  ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const TextSpan(text: 'IN: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      TextSpan(
                        text: '${incoming.name} (${TimeFormatter.formatMmSs(incoming.totalPlayedSeconds)})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: isUrgent ? Colors.amber.shade800 : Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => onExecuteSub(outgoing.playerId, incoming.playerId),
            icon: const Icon(Icons.sync_alt, size: 16),
            label: const Text(
              'SWAP',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
