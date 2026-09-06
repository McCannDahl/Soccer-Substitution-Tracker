import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../models/game_session.dart';
import '../models/team.dart';
import '../widgets/game_timer_card.dart';
import '../widgets/midgame_player_dialog.dart';
import '../widgets/player_card.dart';
import '../widgets/sub_recommendation_banner.dart';
import 'game_summary_screen.dart';

class ActiveGameScreen extends StatefulWidget {
  final GameController gameController;
  final TeamController teamController;

  const ActiveGameScreen({
    super.key,
    required this.gameController,
    required this.teamController,
  });

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  @override
  void initState() {
    super.initState();
    widget.gameController.onPeriodEnded = _onPeriodEnded;
    widget.gameController.onBreakEnded = _onBreakEnded;
  }

  @override
  void dispose() {
    widget.gameController.onPeriodEnded = null;
    widget.gameController.onBreakEnded = null;
    super.dispose();
  }

  void _onPeriodEnded() {
    if (!mounted) return;
    final session = widget.gameController.session;
    if (session == null) return;

    if (session.isGameOver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.indigo,
          content: Text('⚽ Final Whistle! Game Over.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameSummaryScreen(
            session: session,
            teamController: widget.teamController,
            gameController: widget.gameController,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.sports_soccer, size: 48, color: Colors.green),
          title: Text(session.isHalftime ? 'Halftime Break!' : 'Quarter Ended!'),
          content: Text(
            session.isHalftime
                ? 'Halftime break (${session.config.halftimeMinutes} min) has started. Rest and hydrate!'
                : 'Quarter break (${session.config.quarterBreakMinutes} min) has started. Get ready for Quarter ${session.currentPeriod + 1}!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.gameController.skipBreak();
                Navigator.pop(ctx);
              },
              child: const Text('Skip Break'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Start Break Timer'),
            ),
          ],
        ),
      );
    }
  }

  void _onBreakEnded() {
    if (!mounted) return;
    final session = widget.gameController.session;
    if (session == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.timer_off, size: 48, color: Colors.amber),
        title: const Text('Break is Over!'),
        content: Text(
          'Time to start Quarter ${session.currentPeriod} of ${session.config.periods}. Tap Start when ready.',
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              widget.gameController.resumeTimer();
            },
            icon: const Icon(Icons.play_arrow),
            label: Text('Start Quarter ${session.currentPeriod}'),
          ),
        ],
      ),
    );
  }

  void _confirmEndGame() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Game Now?'),
        content: const Text(
          'This will blow the final whistle, stop all timers, and generate the player playing time report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.gameController.endGame();
              final s = widget.gameController.session;
              if (s != null && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameSummaryScreen(
                      session: s,
                      teamController: widget.teamController,
                      gameController: widget.gameController,
                    ),
                  ),
                );
              }
            },
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  void _openAddPlayerDialog(GameSession session) {
    Team? fullTeam;
    try {
      fullTeam = widget.teamController.teams
          .firstWhere((t) => t.id == session.teamId);
    } catch (_) {
      fullTeam = null;
    }

    MidgamePlayerDialogs.showAddPlayerDialog(
      context,
      teamRoster: fullTeam?.players ?? [],
      currentGamePlayers: session.players,
      onAddPlayer: (player, toField) {
        widget.gameController.addPlayerToGame(player, toField: toField);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${player.name} added to ${toField ? "field" : "bench"}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _openStrategyWeightsDialog(GameSession session) {
    int shift = session.config.shiftWeight;
    int total = session.config.totalTimeWeight;
    int skill = session.config.skillWeight;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calculate_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Flexible(child: Text('Substitution Strategy')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coaching Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Default (40/50/10)'),
                      selected: shift == 40 && total == 50 && skill == 10,
                      onSelected: (sel) {
                        if (sel) {
                          setDlgState(() {
                            shift = 40;
                            total = 50;
                            skill = 10;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Fair Play (40/60/0)'),
                      selected: shift == 40 && total == 60 && skill == 0,
                      onSelected: (sel) {
                        if (sel) {
                          setDlgState(() {
                            shift = 40;
                            total = 60;
                            skill = 0;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Competitive (30/30/40)'),
                      selected: shift == 30 && total == 30 && skill == 40,
                      onSelected: (sel) {
                        if (sel) {
                          setDlgState(() {
                            shift = 30;
                            total = 30;
                            skill = 40;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shift Length Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('$shift%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                Slider(
                  value: shift.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$shift%',
                  onChanged: (v) => setDlgState(() => shift = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Game Time Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('$total%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                Slider(
                  value: total.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$total%',
                  onChanged: (v) => setDlgState(() => total = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Player Skill Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('$skill%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                Slider(
                  value: skill.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$skill%',
                  onChanged: (v) => setDlgState(() => skill = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                widget.gameController.updateStrategyWeights(
                  shiftWeight: shift,
                  totalTimeWeight: total,
                  skillWeight: skill,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _onBackPressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Match Screen?'),
        content: const Text(
          'The match and player timers will continue running. You can resume at any time from the home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            child: const Text('Go to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameController,
      builder: (context, _) {
        final session = widget.gameController.session;
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game Tracker')),
            body: const Center(child: Text('No active game session')),
          );
        }

        final onField = session.onFieldPlayers;
        final bench = session.benchPlayers;
        final injured = session.injuredPlayers;
        final (recOut, recIn) = session.recommendedSub;
        final targetCount = session.config.playersOnField;
        final countMismatch = onField.length != targetCount;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBackPressed();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Home',
                onPressed: _onBackPressed,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.teamName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${session.config.playersOnField}v${session.config.playersOnField} • Q${session.currentPeriod} of ${session.config.periods}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                // + Add Player mid-game button
                IconButton.filledTonal(
                  icon: const Icon(Icons.person_add_alt_1, size: 20),
                  tooltip: 'Add Player Mid-Game',
                  onPressed: () => _openAddPlayerDialog(session),
                ),
                const SizedBox(width: 4),

                // End Match quick button
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 22),
                  tooltip: 'End Match (Whistle)',
                  onPressed: _confirmEndGame,
                ),
                const SizedBox(width: 4),

              // Game actions popup menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'strategy') {
                    _openStrategyWeightsDialog(session);
                  } else if (val == 'add_player') {
                    _openAddPlayerDialog(session);
                  } else if (val == 'end_game') {
                    _confirmEndGame();
                  } else if (val == 'cancel_game') {
                    widget.gameController.cancelActiveGame();
                    Navigator.pop(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'strategy',
                    child: Row(
                      children: [
                        Icon(Icons.calculate_outlined, size: 18, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Substitution Strategy / Weights'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_player',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt, size: 18),
                        SizedBox(width: 8),
                        Text('Add Player Mid-Game'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'end_game',
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 18, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('End Game (Whistle)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel_game',
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Discard Match'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Timer Card
              SliverToBoxAdapter(
                child: GameTimerCard(
                  session: session,
                  onTogglePlayPause: widget.gameController.toggleTimer,
                  onSkipBreak: widget.gameController.skipBreak,
                  onAdjustTime: widget.gameController.adjustGameTime,
                ),
              ),

              // Sub Recommendation Banner
              SliverToBoxAdapter(
                child: SubRecommendationBanner(
                  session: session,
                  onExecuteSub: widget.gameController.executeSub,
                ),
              ),

              // ON FIELD HEADER & COUNT STATUS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports_soccer, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ON FIELD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: countMismatch ? Colors.orange.shade700 : Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${onField.length} / $targetCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap player to sub out',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Field Count Warning Banner (if != 4)
              if (countMismatch)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            onField.length < targetCount
                                ? 'Need ${targetCount - onField.length} more player(s) on field (tap bench players below).'
                                : 'Too many players (${onField.length}/$targetCount)! Tap a player to sub out.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ON FIELD PLAYER LIST (Sorted: Longest shift at top!)
              if (onField.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No players on field. Tap bench players below to move them in!',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = onField[index];
                      final isSubOut = recOut?.playerId == player.playerId;
                      return PlayerCard(
                        key: ValueKey(player.playerId),
                        player: player,
                        isRecommendedSubOut: isSubOut,
                        subScore: session.computeSubOutScore(player),
                        subRecommendationMinutes:
                            session.config.subRecommendationMinutes,
                        onTap: () =>
                            widget.gameController.togglePlayerStatus(player.playerId),
                        onUpdateSkill: (newSkill) => widget.gameController
                            .updatePlayerSkill(player.playerId, newSkill),
                        onMarkInjured: () {
                          MidgamePlayerDialogs.showInjuryDialog(
                            context,
                            player: player,
                            onConfirmInjury: (note) => widget.gameController
                                .markPlayerInjured(player.playerId, note: note),
                          );
                        },
                        onAdjustTime: (delta) => widget.gameController
                            .adjustPlayerTime(player.playerId, delta),
                        onRemovePlayer: () => widget.gameController
                            .removePlayerFromGame(player.playerId),
                      );
                    },
                    childCount: onField.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // BENCH HEADER & STATUS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.airline_seat_recline_normal,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BENCH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${bench.length} players',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap player to sub in',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // BENCH PLAYER LIST (Sorted: Highest sub-in priority at top!)
              if (bench.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No players on bench.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = bench[index];
                      final isSubIn = recIn?.playerId == player.playerId;
                      return PlayerCard(
                        key: ValueKey(player.playerId),
                        player: player,
                        isRecommendedSubIn: isSubIn,
                        subScore: session.computeSubInScore(player),
                        subRecommendationMinutes:
                            session.config.subRecommendationMinutes,
                        onTap: () =>
                            widget.gameController.togglePlayerStatus(player.playerId),
                        onUpdateSkill: (newSkill) => widget.gameController
                            .updatePlayerSkill(player.playerId, newSkill),
                        onMarkInjured: () {
                          MidgamePlayerDialogs.showInjuryDialog(
                            context,
                            player: player,
                            onConfirmInjury: (note) => widget.gameController
                                .markPlayerInjured(player.playerId, note: note),
                          );
                        },
                        onAdjustTime: (delta) => widget.gameController
                            .adjustPlayerTime(player.playerId, delta),
                        onRemovePlayer: () => widget.gameController
                            .removePlayerFromGame(player.playerId),
                      );
                    },
                    childCount: bench.length,
                  ),
                ),

              // INJURED / SIDELINED SECTION (If any)
              if (injured.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.healing, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INJURED / SIDELINED (${injured.length})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = injured[index];
                      return PlayerCard(
                        key: ValueKey(player.playerId),
                        player: player,
                        onTap: () => widget.gameController
                            .returnPlayerFromInjury(player.playerId),
                        onReturnFromInjury: () => widget.gameController
                            .returnPlayerFromInjury(player.playerId),
                        onUpdateSkill: (newSkill) => widget.gameController
                            .updatePlayerSkill(player.playerId, newSkill),
                        onRemovePlayer: () => widget.gameController
                            .removePlayerFromGame(player.playerId),
                      );
                    },
                    childCount: injured.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      );
      },
    );
  }
}
