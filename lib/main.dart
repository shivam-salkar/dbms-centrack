import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  final appState = AppState();
  await appState.checkExistingSession();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const CensusTrackerApp(),
    ),
  );
}

class CensusTrackerApp extends StatelessWidget {
  const CensusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'Census Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: appState.currentOfficer != null
              ? const DashboardScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
