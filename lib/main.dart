import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/state/app_state.dart';
import 'core/state/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
         ChangeNotifierProvider(
        create: (_) => AppState()..initialize(), // 🔑 THIS FIXES SPINNER
      ),
      ],
      child: const MyApp(),
    ),
  );
}
