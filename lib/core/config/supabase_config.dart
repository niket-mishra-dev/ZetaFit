// lib/core/config/supabase_config.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = "https://nfghovmfeipdptvmjcxw.supabase.co";
  static const String supabaseAnonKey = "sb_publishable_cwwBJ0pGyetzkGEVfl0gmA_VgasE1Sm";

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode, // prints Supabase logs in debug mode
      );

      if (kDebugMode) {
        print("🔗 Supabase initialized successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Supabase initialization failed: $e");
      }
      rethrow;
    }
  }


  static SupabaseClient get client => Supabase.instance.client;
}
