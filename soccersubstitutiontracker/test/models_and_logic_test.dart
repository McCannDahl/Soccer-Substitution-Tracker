import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccersubstitutiontracker/controllers/game_controller.dart';
import 'package:soccersubstitutiontracker/controllers/team_controller.dart';
import 'package:soccersubstitutiontracker/models/game_config.dart';
import 'package:soccersubstitutiontracker/models/game_session.dart';
import 'package:soccersubstitutiontracker/models/player.dart';
import 'package:soccersubstitutiontracker/models/team.dart';
import 'package:soccersubstitutiontracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameConfig Tests', () {
    test('default configuration matches 6U requirements', () {
      const config = GameConfig();
      expect(config.periods, equals(4)); // 4 quarters
      expect(config.periodDurationMinutes, equals(10)); // 10 min quarters
      expect(config.quarterBreakMinutes, equals(2)); // 2 min quarter breaks
      expect(config.halftimeMinutes, equals(4)); // 4 min halftime
      expect(config.playersOnField, equals(4)); // 4 on 4
      expect(config.subRecommendationMinutes, equals(5)); // 5 min shift target
      expect(config.soundEnabled, isTrue);
      expect(config.vibrationEnabled, isTrue);
    });

    test('custom configuration can be created and serialized', () {
      const config = GameConfig(
        periods: 2,
        periodDurationMinutes: 15,
        quarterBreakMinutes: 1,
        halftimeMinutes: 5,
        playersOnField: 5,
        subRecommendationMinutes: 7,
      );
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);

      expect(restored.periods, equals(2));
      expect(restored.periodDurationMinutes, equals(15));
      expect(restored.playersOnField, equals(5));
    });
  });

  group('GameSession Sorting & Recommendations Tests', () {
    test('onFieldPlayers are sorted by shift duration descending', () {
      final session = GameSession(
        id: 's1',
        teamId: 't1',
        teamName: 'Tigers',
        config: const GameConfig(),
        periodSecondsRemaining: 600,
        startTime: DateTime.now(),
        players: const [
          GamePlayer(
            playerId: 'p1',
            name: 'Leo',
            status: PlayerStatus.onField,
            currentShiftSeconds: 120,
            totalPlayedSeconds: 120,
          ),
          GamePlayer(
            playerId: 'p2',
            name: 'Maya',
            status: PlayerStatus.onField,
            currentShiftSeconds: 340, // Played longest in this shift
            totalPlayedSeconds: 340,
          ),
          GamePlayer(
            playerId: 'p3',
            name: 'Noah',
            status: PlayerStatus.onField,
            currentShiftSeconds: 60,
            totalPlayedSeconds: 60,
          ),
          GamePlayer(
            playerId: 'p4',
            name: 'Emma',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 0,
          ),
        ],
      );

      final onField = session.onFieldPlayers;
      expect(onField.length, equals(3));
      // Maya (340s) must be first because she has been playing longest
      expect(onField.first.name, equals('Maya'));
      expect(onField[1].name, equals('Leo'));
      expect(onField[2].name, equals('Noah'));
    });

    test('benchPlayers are sorted by total played time ascending (least played first)', () {
      final session = GameSession(
        id: 's1',
        teamId: 't1',
        teamName: 'Tigers',
        config: const GameConfig(),
        periodSecondsRemaining: 600,
        startTime: DateTime.now(),
        players: const [
          GamePlayer(
            playerId: 'p1',
            name: 'Leo',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 300,
          ),
          GamePlayer(
            playerId: 'p2',
            name: 'Maya',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 90, // Played least overall
          ),
          GamePlayer(
            playerId: 'p3',
            name: 'Noah',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 200,
          ),
        ],
      );

      final bench = session.benchPlayers;
      expect(bench.length, equals(3));
      // Maya (90s) must be first because she needs playing time most!
      expect(bench.first.name, equals('Maya'));
      expect(bench[1].name, equals('Noah'));
      expect(bench[2].name, equals('Leo'));
    });

    test('recommendedSub pairs longest on-field player with least-played bench player', () {
      final session = GameSession(
        id: 's1',
        teamId: 't1',
        teamName: 'Tigers',
        config: const GameConfig(),
        periodSecondsRemaining: 600,
        startTime: DateTime.now(),
        players: const [
          GamePlayer(
            playerId: 'p1',
            name: 'Leo',
            status: PlayerStatus.onField,
            currentShiftSeconds: 400, // On field longest
            totalPlayedSeconds: 400,
          ),
          GamePlayer(
            playerId: 'p2',
            name: 'Maya',
            status: PlayerStatus.onField,
            currentShiftSeconds: 200,
            totalPlayedSeconds: 200,
          ),
          GamePlayer(
            playerId: 'p3',
            name: 'Noah',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 60, // Played least on bench
          ),
          GamePlayer(
            playerId: 'p4',
            name: 'Emma',
            status: PlayerStatus.bench,
            totalPlayedSeconds: 180,
          ),
        ],
      );

      final (outgoing, incoming) = session.recommendedSub;
      expect(outgoing?.name, equals('Leo'));
      expect(incoming?.name, equals('Noah'));
    });
  });

  group('GameController & Flow Tests', () {
    late StorageService storage;
    late GameController gameController;
    late Team testTeam;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      gameController = GameController(storage);

      testTeam = Team(
        id: 'team_test',
        name: 'Test FC',
        createdAt: DateTime(2026, 1, 1),
        players: const [
          Player(id: 'p1', name: 'Player 1', number: 1),
          Player(id: 'p2', name: 'Player 2', number: 2),
          Player(id: 'p3', name: 'Player 3', number: 3),
          Player(id: 'p4', name: 'Player 4', number: 4),
          Player(id: 'p5', name: 'Player 5', number: 5),
          Player(id: 'p6', name: 'Player 6', number: 6),
        ],
      );
    });

    tearDown(() {
      gameController.dispose();
    });

    test('startGame initializes 4 on field and 2 on bench', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      expect(gameController.hasActiveGame, isTrue);
      final session = gameController.session!;
      expect(session.currentPeriod, equals(1));
      expect(session.periodType, equals(GamePeriodType.quarter));
      expect(session.periodSecondsRemaining, equals(600)); // 10 min
      expect(session.onFieldPlayers.length, equals(4));
      expect(session.benchPlayers.length, equals(2));
    });

    test('togglePlayerStatus switches player from field to bench and vice versa', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      // p1 is on field, toggle should move to bench
      gameController.togglePlayerStatus('p1');
      expect(
        gameController.session!.players.firstWhere((p) => p.playerId == 'p1').status,
        equals(PlayerStatus.bench),
      );
      expect(gameController.session!.onFieldPlayers.length, equals(3));
      expect(gameController.session!.benchPlayers.length, equals(3));

      // p1 is on bench, toggle should move back to field
      gameController.togglePlayerStatus('p1');
      expect(
        gameController.session!.players.firstWhere((p) => p.playerId == 'p1').status,
        equals(PlayerStatus.onField),
      );
      expect(gameController.session!.onFieldPlayers.length, equals(4));
    });

    test('executeSub swaps outgoing and incoming players in one operation', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      expect(gameController.session!.players.firstWhere((p) => p.playerId == 'p1').isOnField, isTrue);
      expect(gameController.session!.players.firstWhere((p) => p.playerId == 'p5').isOnBench, isTrue);

      gameController.executeSub('p1', 'p5');

      expect(gameController.session!.players.firstWhere((p) => p.playerId == 'p1').isOnBench, isTrue);
      expect(gameController.session!.players.firstWhere((p) => p.playerId == 'p5').isOnField, isTrue);
    });

    test('injury management: sideline player mid-game and return when recovered', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      // p2 gets hurt on field
      gameController.markPlayerInjured('p2', note: 'Knee scrape');
      final injuredP2 =
          gameController.session!.players.firstWhere((p) => p.playerId == 'p2');
      expect(injuredP2.status, equals(PlayerStatus.injured));
      expect(injuredP2.injuryNote, equals('Knee scrape'));
      expect(gameController.session!.injuredPlayers.length, equals(1));
      expect(gameController.session!.onFieldPlayers.length, equals(3));

      // p2 recovers, coach returns them to bench
      gameController.returnPlayerFromInjury('p2');
      final recoveredP2 =
          gameController.session!.players.firstWhere((p) => p.playerId == 'p2');
      expect(recoveredP2.status, equals(PlayerStatus.bench));
      expect(gameController.session!.injuredPlayers.isEmpty, isTrue);
    });

    test('addPlayerToGame adds late-arriving kid mid-game', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players.take(4).toList(),
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      expect(gameController.session!.players.length, equals(4));

      // Kid arrives 5 minutes in
      const lateKid = Player(id: 'late_kid', name: 'Oliver', number: 12);
      gameController.addPlayerToGame(lateKid, toField: false);

      expect(gameController.session!.players.length, equals(5));
      final added =
          gameController.session!.players.firstWhere((p) => p.playerId == 'late_kid');
      expect(added.name, equals('Oliver'));
      expect(added.isOnBench, isTrue);
      expect(added.totalPlayedSeconds, equals(0));
    });

    test('adjustPlayerTime adds or subtracts minutes correctly', () {
      gameController.startGame(
        team: testTeam,
        attendingPlayers: testTeam.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      gameController.adjustPlayerTime('p1', 120); // +2 minutes
      var p1 = gameController.session!.players.firstWhere((p) => p.playerId == 'p1');
      expect(p1.totalPlayedSeconds, equals(120));

      gameController.adjustPlayerTime('p1', -60); // -1 minute
      p1 = gameController.session!.players.firstWhere((p) => p.playerId == 'p1');
      expect(p1.totalPlayedSeconds, equals(60));
    });
  });

  group('TeamController Tests', () {
    late StorageService storage;
    late TeamController teamController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      teamController = TeamController(storage);
    });

    test('create, update, and delete team with roster', () async {
      final team = await teamController.createTeam('Hawks 6U', [
        const Player(id: 'h1', name: 'Lucas', number: 5),
      ]);
      expect(teamController.teams.any((t) => t.id == team.id), isTrue);

      await teamController.addPlayer(team.id, const Player(id: 'h2', name: 'Sophia', number: 10));
      final updated = teamController.teams.firstWhere((t) => t.id == team.id);
      expect(updated.players.length, equals(2));

      await teamController.deleteTeam(team.id);
      expect(teamController.teams.any((t) => t.id == team.id), isFalse);
    });
  });

  group('Persistence & Crash-Recovery Verification Tests', () {
    test('teams and players survive simulated app kill and phone reboot', () async {
      // 1. Initial boot: empty prefs
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      final storage1 = await StorageService.init();
      final teamController1 = TeamController(storage1);

      // Create custom team with 5 players
      final createdTeam = await teamController1.createTeam('Dragons 6U', const [
        Player(id: 'd1', name: 'Mason', number: 10),
        Player(id: 'd2', name: 'Chloe', number: 5),
      ]);
      await teamController1.addPlayer(
        createdTeam.id,
        const Player(id: 'd3', name: 'Zack', number: 8),
      );

      expect(teamController1.teams.any((t) => t.name == 'Dragons 6U'), isTrue);

      // 2. SIMULATE REBOOT: All memory dropped, new StorageService reading the same underlying disk storage
      final storage2 = await StorageService.init();
      final teamController2 = TeamController(storage2);

      final recoveredTeam =
          teamController2.teams.firstWhere((t) => t.id == createdTeam.id);
      expect(recoveredTeam.name, equals('Dragons 6U'));
      expect(recoveredTeam.players.length, equals(3));
      expect(recoveredTeam.players.map((p) => p.name), containsAll(['Mason', 'Chloe', 'Zack']));
    });

    test('midgame crash recovery restores exact game clock, active shift times, and player statuses', () async {
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      final storage1 = await StorageService.init();
      final teamController1 = TeamController(storage1);
      final gameController1 = GameController(storage1);

      final team = teamController1.teams.first; // Rainbow Fire
      gameController1.startGame(
        team: team,
        attendingPlayers: team.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(periodDurationMinutes: 10, playersOnField: 4),
      );

      // Simulate 3 minutes (180 seconds) of play time
      gameController1.adjustGameTime(-180); // 420s remaining
      gameController1.adjustPlayerTime('p1', 180);
      gameController1.adjustPlayerTime('p2', 180);
      // Perform a sub mid-game: swap p1 out for p5
      gameController1.executeSub('p1', 'p5');
      // Sidelined injury: p2 injured
      gameController1.markPlayerInjured('p2', note: 'Twisted ankle');

      expect(gameController1.session!.onFieldPlayers.length, equals(3));
      expect(gameController1.session!.injuredPlayers.length, equals(1));
      expect(gameController1.session!.periodSecondsRemaining, equals(420));

      // 2. SIMULATE APP CRASH / KILLED BY OS
      gameController1.dispose();

      // 3. REBOOT APP: Fresh instances created
      final storage2 = await StorageService.init();
      final gameController2 = GameController(storage2);

      // Verify active game exists and is fully restored
      expect(gameController2.hasActiveGame, isTrue);
      final recoveredSession = gameController2.session!;
      expect(recoveredSession.teamName, equals('Rainbow Fire'));
      expect(recoveredSession.currentPeriod, equals(1));
      expect(recoveredSession.periodSecondsRemaining, equals(420));
      expect(recoveredSession.isTimerRunning, isFalse); // Paused safely on restore

      // Check player statuses recovered identically
      final p1 = recoveredSession.players.firstWhere((p) => p.playerId == 'p1');
      final p2 = recoveredSession.players.firstWhere((p) => p.playerId == 'p2');
      final p5 = recoveredSession.players.firstWhere((p) => p.playerId == 'p5');

      expect(p1.isOnBench, isTrue);
      expect(p1.totalPlayedSeconds, equals(180));
      expect(p2.isInjured, isTrue);
      expect(p2.injuryNote, equals('Twisted ankle'));
      expect(p5.isOnField, isTrue);

      // Verify game can be resumed cleanly
      gameController2.resumeTimer();
      expect(gameController2.isTimerRunning, isTrue);

      gameController2.dispose();
    });

    test('match history persists across app restarts after final whistle', () async {
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      final storage1 = await StorageService.init();
      final gameController1 = GameController(storage1);
      final team = (await StorageService.init()).getTeams().first;

      gameController1.startGame(
        team: team,
        attendingPlayers: team.players,
        startingFieldPlayerIds: ['p1', 'p2', 'p3', 'p4'],
        config: const GameConfig(),
      );

      // Coach ends match
      gameController1.endGame();
      expect(gameController1.hasActiveGame, isFalse);
      gameController1.dispose();

      // Reboot app
      final storage2 = await StorageService.init();
      final gameController2 = GameController(storage2);

      expect(gameController2.hasActiveGame, isFalse);
      final history = storage2.getGameHistory();
      expect(history.length, equals(1));
      expect(history.first.teamName, equals(team.name));
      expect(history.first.isGameOver, isTrue);

      gameController2.dispose();
    });

    test('custom match rules persist across app restarts', () async {
      final mockData = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockData);

      final storage1 = await StorageService.init();
      const customRules = GameConfig(
        periods: 2,
        periodDurationMinutes: 12,
        quarterBreakMinutes: 3,
        halftimeMinutes: 6,
        playersOnField: 5,
        subRecommendationMinutes: 6,
      );
      await storage1.saveGameConfig(customRules);

      // Reboot app
      final storage2 = await StorageService.init();
      final loadedRules = storage2.getGameConfig();

      expect(loadedRules.periods, equals(2));
      expect(loadedRules.periodDurationMinutes, equals(12));
      expect(loadedRules.quarterBreakMinutes, equals(3));
      expect(loadedRules.halftimeMinutes, equals(6));
      expect(loadedRules.playersOnField, equals(5));
      expect(loadedRules.subRecommendationMinutes, equals(6));
    });
  });
}
