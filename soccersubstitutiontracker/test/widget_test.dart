import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccersubstitutiontracker/controllers/game_controller.dart';
import 'package:soccersubstitutiontracker/controllers/team_controller.dart';
import 'package:soccersubstitutiontracker/main.dart';
import 'package:soccersubstitutiontracker/models/game_config.dart';
import 'package:soccersubstitutiontracker/screens/active_game_screen.dart';
import 'package:soccersubstitutiontracker/services/storage_service.dart';

void main() {
  testWidgets('App launches on HomeScreen with default 6U soccer options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final teamController = TeamController(storage);
    final gameController = GameController(storage);

    await tester.pumpWidget(
      SoccerSubTrackerApp(
        storageService: storage,
        teamController: teamController,
        gameController: gameController,
      ),
    );

    // Verify Home screen elements
    expect(find.text('Sub Tracker'), findsOneWidget);
    expect(find.text('Start a Game'), findsOneWidget);
    expect(find.text('Manage Teams & Rosters'), findsOneWidget);
    expect(find.text('Match Reports & History'), findsOneWidget);
    expect(find.text('Default 6U Match Rules'), findsOneWidget);

    // Tap "Start a Game"
    await tester.tap(find.text('Start a Game'));
    await tester.pumpAndSettle();

    // Verify New Game Setup Screen loaded
    expect(find.text('New Game Setup'), findsOneWidget);
    expect(find.text('KICK OFF GAME'), findsOneWidget);
    expect(find.text('Match Rules & Timers'), findsOneWidget);
  });

  testWidgets('ActiveGameScreen allows tapping to toggle in/out, recommends subs, and controls timer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final teamController = TeamController(storage);
    final gameController = GameController(storage);

    final starterTeam = teamController.teams.first; // Rainbow Fire with 9 players

    gameController.startGame(
      team: starterTeam,
      attendingPlayers: starterTeam.players,
      startingFieldPlayerIds: starterTeam.players.take(4).map((p) => p.id).toList(),
      config: const GameConfig(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ActiveGameScreen(
          gameController: gameController,
          teamController: teamController,
        ),
      ),
    );

    // Verify game header & counts
    expect(find.text('Rainbow Fire'), findsOneWidget);
    expect(find.text('Quarter 1 of 4'), findsOneWidget);
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('5 players'), findsOneWidget);

    // Verify PAUSE button is visible because timer starts running
    expect(find.text('PAUSE'), findsOneWidget);

    // Tap PAUSE
    await tester.tap(find.text('PAUSE'));
    await tester.pumpAndSettle();
    expect(find.text('START'), findsOneWidget);

    // Verify player cards: KT is on field, Clayton is on bench
    expect(find.text('KT'), findsOneWidget);
    expect(find.text('Clayton'), findsOneWidget);

    // Tap KT's card to toggle out to bench
    await tester.tap(find.text('KT'));
    await tester.pumpAndSettle();

    // Field count should now be 3 / 4 and warning visible
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('6 players'), findsOneWidget);

    // Tap Clayton's card to toggle into field
    await tester.tap(find.text('Clayton'));
    await tester.pumpAndSettle();

    // Field count back to 4 / 4
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('5 players'), findsOneWidget);

    // Verify Add Player button works
    expect(find.byIcon(Icons.person_add_alt_1), findsWidgets);
    await tester.tap(find.byIcon(Icons.person_add_alt_1).first);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add Player Mid-Game'),
      ),
      findsOneWidget,
    );
    expect(find.text('Add Guest / New Player:'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
