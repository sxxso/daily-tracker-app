import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/habit_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'screens/home_shell.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const DailyTrackerApp());
}

class DailyTrackerApp extends StatelessWidget {
  const DailyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: DatabaseService.instance),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(DatabaseService.instance)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider(DatabaseService.instance)..init(),
        ),
      ],
      child: MaterialApp(
        title: '每日打卡',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
