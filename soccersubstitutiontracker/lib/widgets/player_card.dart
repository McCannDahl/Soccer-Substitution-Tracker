import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../utils/time_formatter.dart';

class PlayerCard extends StatelessWidget {
  final GamePlayer player;
  final VoidCallback onTap;
  final VoidCallback? onMarkInjured;
  final VoidCallback? onReturnFromInjury;
  final VoidCallback? onRemovePlayer;
  final void Function(int deltaSeconds)? onAdjustTime;
  final void Function(int newSkill)? onUpdateSkill;
  final int subRecommendationMinutes;
  final bool isRecommendedSubOut;
  final bool isRecommendedSubIn;
  final double? subScore;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onTap,
    this.onMarkInjured,
    this.onReturnFromInjury,
    this.onRemovePlayer,
    this.onAdjustTime,
    this.onUpdateSkill,
    this.subRecommendationMinutes = 5,
    this.isRecommendedSubOut = false,
    this.isRecommendedSubIn = false,
    this.subScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnField = player.isOnField;
    final isInjured = player.isInjured;

    // Shift urgency calculation (only relevant when on field)
    final shiftSeconds = player.currentShiftSeconds;
    final subTargetSeconds = subRecommendationMinutes * 60;
    Color shiftColor = Colors.green.shade700;
    if (shiftSeconds >= subTargetSeconds) {
      shiftColor = Colors.red.shade700;
    } else if (shiftSeconds >= (subTargetSeconds * 0.75).toInt()) {
      shiftColor = Colors.orange.shade800;
    }

    // Card background styling
    Color cardBorderColor;
    Color cardBgColor;
    if (isInjured) {
      cardBorderColor = Colors.red.shade300;
      cardBgColor = Colors.red.shade50;
    } else if (isOnField) {
      cardBorderColor = isRecommendedSubOut ? Colors.red.shade400 : Colors.green.shade400;
      cardBgColor = isRecommendedSubOut
          ? Colors.red.shade50.withAlpha(120)
          : Colors.green.shade50.withAlpha(90);
    } else {
      cardBorderColor = isRecommendedSubIn ? Colors.teal.shade400 : Colors.grey.shade300;
      cardBgColor = isRecommendedSubIn
          ? Colors.teal.shade50.withAlpha(120)
          : theme.colorScheme.surface;
    }

    return Card(
      elevation: isOnField ? 2.5 : 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cardBorderColor,
          width: (isRecommendedSubOut || isRecommendedSubIn) ? 2.0 : 1.0,
        ),
      ),
      color: cardBgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isInjured ? onReturnFromInjury : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Jersey Number Badge
              CircleAvatar(
                radius: 20,
                backgroundColor: isOnField
                    ? Colors.green.shade700
                    : (isInjured ? Colors.red.shade700 : Colors.blueGrey.shade600),
                foregroundColor: Colors.white,
                child: Text(
                  player.number != null ? '#${player.number}' : player.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),

              // Player Name & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                                '${player.skill}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isRecommendedSubOut) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SUB OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isRecommendedSubIn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SUB IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isInjured) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.healing, size: 12, color: Colors.red.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  'INJURED',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Metrics Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isOnField) ...[
                          // Sub score pill
                          if (subScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: subScore! >= 100
                                    ? Colors.red.shade700
                                    : (subScore! >= 75
                                        ? Colors.orange.shade800
                                        : Colors.green.shade700),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Sub: ${subScore!.round()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // Shift timer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: shiftColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: shiftColor),
                                const SizedBox(width: 3),
                                Text(
                                  'Shift: ${TimeFormatter.formatMmSs(player.currentShiftSeconds)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: shiftColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total played
                          Text(
                            'Total: ${TimeFormatter.formatMmSs(player.totalPlayedSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else if (isInjured) ...[
                          Text(
                            player.injuryNote ?? 'Sidelined - tap to return to bench',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ] else ...[
                          // On Bench
                          if (subScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Priority: ${subScore!.round()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Text(
                            'Total: ${TimeFormatter.formatMmSs(player.totalPlayedSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Rest: ${TimeFormatter.formatMmSs(player.currentBenchSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons / Menu
              if (isInjured)
                FilledButton.tonal(
                  onPressed: onReturnFromInjury,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Return', style: TextStyle(fontSize: 12)),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick In/Out toggle indicator icon
                    IconButton(
                      icon: Icon(
                        isOnField ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isOnField ? Colors.orange.shade800 : Colors.green.shade700,
                      ),
                      tooltip: isOnField ? 'Move to Bench' : 'Move to Field',
                      onPressed: onTap,
                    ),

                    // More Options Popup Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (action) {
                        switch (action) {
                          case 'injure':
                            onMarkInjured?.call();
                            break;
                          case 'skill':
                            _showChangeSkillDialog(context);
                            break;
                          case 'add_1m':
                            onAdjustTime?.call(60);
                            break;
                          case 'sub_1m':
                            onAdjustTime?.call(-60);
                            break;
                          case 'remove':
                            onRemovePlayer?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onUpdateSkill != null)
                          const PopupMenuItem(
                            value: 'skill',
                            child: Row(
                              children: [
                                Icon(Icons.star_outline, size: 18, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Adjust Skill Level'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'injure',
                          child: Row(
                            children: [
                              Icon(Icons.healing, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Mark Injured / Sidelined'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_1m',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Add +1 Min Play Time'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'sub_1m',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Subtract -1 Min Play Time'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove_outlined, size: 18, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Remove from Game (Left)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeSkillDialog(BuildContext context) {
    int currentSkill = player.skill;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Adjust Skill: ${player.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Skill Level:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const SizedBox(width: 4),
                        Text('$currentSkill / 10', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: currentSkill.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$currentSkill',
                onChanged: (v) => setDlgState(() => currentSkill = v.round()),
              ),
              Text(
                currentSkill >= 8
                    ? 'Star Player (Plays longer shifts)'
                    : (currentSkill >= 4 ? 'Balanced Player' : 'Developing Player'),
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                onUpdateSkill?.call(currentSkill);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
