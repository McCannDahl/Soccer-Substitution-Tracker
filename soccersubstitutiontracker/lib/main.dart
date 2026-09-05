import 'package:flutter/material.dart';
import 'controllers/game_controller.dart';
import 'controllers/team_controller.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  final teamController = TeamController(storageService);
  final gameController = GameController(storageService);

  runApp(
    SoccerSubTrackerApp(
      storageService: storageService,
      teamController: teamController,
      gameController: gameController,
    ),
  );
}

class SoccerSubTrackerApp extends StatelessWidget {
  final StorageService storageService;
  final TeamController teamController;
  final GameController gameController;

  const SoccerSubTrackerApp({
    super.key,
    required this.storageService,
    required this.teamController,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soccer Sub Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Forest/Soccer pitch green
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        storageService: storageService,
        teamController: teamController,
        gameController: gameController,
      ),
    );
  }
}
