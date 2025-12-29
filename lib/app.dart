import 'package:fitmor/app_rootshell.dart';
import 'package:fitmor/routes/app_routes.dart';
import 'package:fitmor/state/providers/theme_provider.dart';
import 'package:fitmor/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
     final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'ZetaFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const RootShell(),   // <-- USE ROOTSHELL
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
