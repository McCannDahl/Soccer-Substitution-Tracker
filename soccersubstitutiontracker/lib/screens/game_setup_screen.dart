import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../controllers/team_controller.dart';
import '../models/game_config.dart';
import '../models/player.dart';
import '../models/team.dart';
import 'active_game_screen.dart';
import 'team_edit_screen.dart';

class GameSetupScreen extends StatefulWidget {
  final TeamController teamController;
  final GameController gameController;
  final Team? preselectedTeam;

  const GameSetupScreen({
    super.key,
    required this.teamController,
    required this.gameController,
    this.preselectedTeam,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  Team? _selectedTeam;
  final Set<String> _attendingPlayerIds = {};
  final Set<String> _startingFieldPlayerIds = {};

  // Config defaults matching user prompt
  int _periods = 4;
  int _periodMinutes = 10;
  int _quarterBreakMinutes = 2;
  int _halftimeMinutes = 4;
  int _playersOnField = 4;
  int _subShiftMinutes = 5;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _shiftWeight = 40;
  int _totalTimeWeight = 50;
  int _skillWeight = 10;

  bool _isConfigExpanded = false;
  bool _isStrategyExpanded = false;

  @override
  void initState() {
    super.initState();
    final savedConfig = widget.gameController.storage.getGameConfig();
    _periods = savedConfig.periods;
    _periodMinutes = savedConfig.periodDurationMinutes;
    _quarterBreakMinutes = savedConfig.quarterBreakMinutes;
    _halftimeMinutes = savedConfig.halftimeMinutes;
    _playersOnField = savedConfig.playersOnField;
    _subShiftMinutes = savedConfig.subRecommendationMinutes;
    _soundEnabled = savedConfig.soundEnabled;
    _vibrationEnabled = savedConfig.vibrationEnabled;
    _shiftWeight = savedConfig.shiftWeight;
    _totalTimeWeight = savedConfig.totalTimeWeight;
    _skillWeight = savedConfig.skillWeight;

    final teams = widget.teamController.teams;
    if (widget.preselectedTeam != null) {
      _selectedTeam = widget.preselectedTeam;
    } else if (teams.isNotEmpty) {
      _selectedTeam = teams.first;
    }
    _initAttendance();
  }

  void _initAttendance() {
    if (_selectedTeam != null) {
      _attendingPlayerIds.clear();
      _startingFieldPlayerIds.clear();

      for (final p in _selectedTeam!.players) {
        _attendingPlayerIds.add(p.id);
      }

      // Auto-select starting players up to _playersOnField
      final startCount = _selectedTeam!.players.length < _playersOnField
          ? _selectedTeam!.players.length
          : _playersOnField;
      for (int i = 0; i < startCount; i++) {
        _startingFieldPlayerIds.add(_selectedTeam!.players[i].id);
      }
    }
  }

  void _autoPickStarting() {
    setState(() {
      _startingFieldPlayerIds.clear();
      final attending = _selectedTeam?.players
              .where((p) => _attendingPlayerIds.contains(p.id))
              .toList() ??
          [];
      final count = attending.length < _playersOnField ? attending.length : _playersOnField;
      for (int i = 0; i < count; i++) {
        _startingFieldPlayerIds.add(attending[i].id);
      }
    });
  }

  void _startGame() {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team')),
      );
      return;
    }

    final attending = _selectedTeam!.players
        .where((p) => _attendingPlayerIds.contains(p.id))
        .toList();

    if (attending.length < _playersOnField) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need at least $_playersOnField players attending (currently ${attending.length})',
          ),
        ),
      );
      return;
    }

    if (_startingFieldPlayerIds.length != _playersOnField) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly $_playersOnField players to start on the field (currently ${_startingFieldPlayerIds.length})',
          ),
        ),
      );
      return;
    }

    final config = GameConfig(
      periods: _periods,
      periodDurationMinutes: _periodMinutes,
      quarterBreakMinutes: _quarterBreakMinutes,
      halftimeMinutes: _halftimeMinutes,
      playersOnField: _playersOnField,
      subRecommendationMinutes: _subShiftMinutes,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
      shiftWeight: _shiftWeight,
      totalTimeWeight: _totalTimeWeight,
      skillWeight: _skillWeight,
    );

    widget.gameController.storage.saveGameConfig(config);

    widget.gameController.startGame(
      team: _selectedTeam!,
      attendingPlayers: attending,
      startingFieldPlayerIds: _startingFieldPlayerIds.toList(),
      config: config,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveGameScreen(
          gameController: widget.gameController,
          teamController: widget.teamController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = widget.teamController.teams;

    if (teams.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Setup')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No teams available. Create a team first!'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TeamEditScreen(teamController: widget.teamController),
                    ),
                  );
                },
                child: const Text('Create Team'),
              ),
            ],
          ),
        ),
      );
    }

    final attendingList = _selectedTeam?.players
            .where((p) => _attendingPlayerIds.contains(p.id))
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team Selector
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Team',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Team>(
                      initialValue: _selectedTeam,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: teams.map((team) {
                        return DropdownMenuItem<Team>(
                          value: team,
                          child: Text('${team.name} (${team.players.length} players)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTeam = val;
                          _initAttendance();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Configurable Match Rules (Accordion)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                initiallyExpanded: _isConfigExpanded,
                onExpansionChanged: (exp) => setState(() => _isConfigExpanded = exp),
                leading: const Icon(Icons.settings_outlined, color: Colors.teal),
                title: const Text(
                  'Match Rules & Timers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$_periods quarters • ${_periodMinutes}m each • ${_playersOnField}v$_playersOnField • ${_quarterBreakMinutes}m break • ${_halftimeMinutes}m halftime',
                  style: const TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        // Quarters count
                        _buildCounterRow(
                          title: 'Number of Quarters / Periods',
                          subtitle: 'Default: 4 quarters',
                          value: _periods,
                          min: 1,
                          max: 6,
                          onChanged: (v) => setState(() => _periods = v),
                        ),
                        // Quarter length
                        _buildCounterRow(
                          title: 'Quarter Duration',
                          subtitle: 'Default: 10 minutes',
                          value: _periodMinutes,
                          min: 1,
                          max: 45,
                          suffix: 'min',
                          onChanged: (v) => setState(() => _periodMinutes = v),
                        ),
                        // Quarter break
                        _buildCounterRow(
                          title: 'Quarter Break Duration',
                          subtitle: 'Between Q1-Q2 and Q3-Q4 (default: 2 min)',
                          value: _quarterBreakMinutes,
                          min: 0,
                          max: 15,
                          suffix: 'min',
                          onChanged: (v) => setState(() => _quarterBreakMinutes = v),
                        ),
                        // Halftime
                        _buildCounterRow(
                          title: 'Halftime Duration',
                          subtitle: 'Between Q2-Q3 (default: 4 min)',
                          value: _halftimeMinutes,
                          min: 0,
                          max: 20,
                          suffix: 'min',
                          onChanged: (v) => setState(() => _halftimeMinutes = v),
                        ),
                        // Players on field
                        _buildCounterRow(
                          title: 'Players on Field',
                          subtitle: 'Default: 4 on 4 (6U soccer)',
                          value: _playersOnField,
                          min: 2,
                          max: 11,
                          suffix: 'players',
                          onChanged: (v) {
                            setState(() {
                              _playersOnField = v;
                              _autoPickStarting();
                            });
                          },
                        ),
                        // Sub shift recommendation target
                        _buildCounterRow(
                          title: 'Sub Recommendation Target',
                          subtitle: 'Alert when a player shift reaches this limit',
                          value: _subShiftMinutes,
                          min: 1,
                          max: 15,
                          suffix: 'min',
                          onChanged: (v) => setState(() => _subShiftMinutes = v),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Sound Alerts', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Play sound chime when quarter or break ends', style: TextStyle(fontSize: 12)),
                          value: _soundEnabled,
                          onChanged: (val) => setState(() => _soundEnabled = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Vibration Feedback', style: TextStyle(fontSize: 14)),
                          subtitle: const Text('Vibrate phone on timer events', style: TextStyle(fontSize: 12)),
                          value: _vibrationEnabled,
                          onChanged: (val) => setState(() => _vibrationEnabled = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Substitution Strategy & Weights Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                initiallyExpanded: _isStrategyExpanded,
                onExpansionChanged: (exp) => setState(() => _isStrategyExpanded = exp),
                leading: const Icon(Icons.calculate_outlined, color: Colors.indigo),
                title: const Text(
                  'Substitution Score & Strategy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Shift $_shiftWeight% • Total Time $_totalTimeWeight% • Skill $_skillWeight%',
                  style: const TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text(
                          'Coaching Presets:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Default (40/50/10)'),
                              selected: _shiftWeight == 40 && _totalTimeWeight == 50 && _skillWeight == 10,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() {
                                    _shiftWeight = 40;
                                    _totalTimeWeight = 50;
                                    _skillWeight = 10;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Fair Play (40/60/0)'),
                              selected: _shiftWeight == 40 && _totalTimeWeight == 60 && _skillWeight == 0,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() {
                                    _shiftWeight = 40;
                                    _totalTimeWeight = 60;
                                    _skillWeight = 0;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Competitive (30/30/40)'),
                              selected: _shiftWeight == 30 && _totalTimeWeight == 30 && _skillWeight == 40,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() {
                                    _shiftWeight = 30;
                                    _totalTimeWeight = 30;
                                    _skillWeight = 40;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Current Shift Weight Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Shift Length Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('$_shiftWeight%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        Slider(
                          value: _shiftWeight.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$_shiftWeight%',
                          onChanged: (v) => setState(() => _shiftWeight = v.round()),
                        ),
                        // Total Game Time Weight Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Game Time Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('$_totalTimeWeight%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        Slider(
                          value: _totalTimeWeight.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$_totalTimeWeight%',
                          onChanged: (v) => setState(() => _totalTimeWeight = v.round()),
                        ),
                        // Skill Weight Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Player Skill Rating Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('$_skillWeight%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        Slider(
                          value: _skillWeight.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$_skillWeight%',
                          onChanged: (v) => setState(() => _skillWeight = v.round()),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '💡 Substitution Score balances how long someone has been on the field this shift, how much total game time they have had compared to teammates, and their 1-10 skill rating.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Attendance Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Who is Here Today? (${_attendingPlayerIds.length}/${_selectedTeam?.players.length ?? 0})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_attendingPlayerIds.length == (_selectedTeam?.players.length ?? 0)) {
                                _attendingPlayerIds.clear();
                                _startingFieldPlayerIds.clear();
                              } else {
                                for (final p in _selectedTeam?.players ?? <Player>[]) {
                                  _attendingPlayerIds.add(p.id);
                                }
                                _autoPickStarting();
                              }
                            });
                          },
                          child: Text(
                            _attendingPlayerIds.length == (_selectedTeam?.players.length ?? 0)
                                ? 'Clear All'
                                : 'Select All',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_selectedTeam != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTeam!.players.map((p) {
                          final isAttending = _attendingPlayerIds.contains(p.id);
                          return FilterChip(
                            avatar: CircleAvatar(
                              backgroundColor: isAttending ? Colors.green.shade800 : Colors.grey,
                              foregroundColor: Colors.white,
                              child: Text(
                                p.number != null ? '${p.number}' : p.name[0],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(
                              p.name,
                              style: TextStyle(
                                color: isAttending ? const Color(0xFF003300) : null,
                                fontWeight: isAttending ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isAttending,
                            selectedColor: Colors.green.shade200,
                            checkmarkColor: const Color(0xFF003300),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _attendingPlayerIds.add(p.id);
                                } else {
                                  _attendingPlayerIds.remove(p.id);
                                  _startingFieldPlayerIds.remove(p.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Starting Lineup (Choose 4)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Starting Lineup (On Field)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Select $_playersOnField players to start (${_startingFieldPlayerIds.length}/$_playersOnField selected)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _startingFieldPlayerIds.length == _playersOnField
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _autoPickStarting,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Auto Pick'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attendingList.map((p) {
                        final isStarting = _startingFieldPlayerIds.contains(p.id);
                        return ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: isStarting ? Colors.green.shade900 : Colors.blueGrey,
                            foregroundColor: Colors.white,
                            child: Text(
                              p.number != null ? '${p.number}' : p.name[0],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          label: Text(
                            isStarting ? '${p.name} (Starting)' : p.name,
                            style: TextStyle(
                              color: isStarting ? const Color(0xFF003300) : null,
                              fontWeight: isStarting ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isStarting,
                          selectedColor: Colors.green.shade200,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_startingFieldPlayerIds.length < _playersOnField) {
                                  _startingFieldPlayerIds.add(p.id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      content: Text(
                                        'Already selected $_playersOnField starting players. Uncheck one first.',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                _startingFieldPlayerIds.remove(p.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Start Game Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startGame,
              icon: const Icon(Icons.sports_soccer, size: 24),
              label: const Text(
                'KICK OFF GAME',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    String? suffix,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                alignment: Alignment.center,
                child: Text(
                  suffix != null ? '$value $suffix' : '$value',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
