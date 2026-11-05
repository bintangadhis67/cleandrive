import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens.dart';
import 'theme.dart';

void main() => runApp(const CleanDriveApp());

class CleanDriveApp extends StatelessWidget {
  const CleanDriveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CleanDrive',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: ListenableBuilder(
          listenable: app,
          builder: (_, __) => app.user == null
              ? const AuthScreen()
              : (app.isAdmin ? const AdminScreen() : const HomeScreen()),
        ),
      );
}
