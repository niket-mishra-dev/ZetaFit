// lib/core/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _db = Supabase.instance.client;

  /// Simple SELECT query
  static Future<List<Map<String, dynamic>>> select({
    required String table,
    String? filterColumn,
    dynamic filterValue,
  }) async {
    try {
      final query = _db.from(table).select();

      if (filterColumn != null) {
        query.eq(filterColumn, filterValue);
      }

      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception("Supabase select error: $e");
    }
  }

  /// Insert or upsert data
  static Future<void> upsert(String table, Map<String, dynamic> values) async {
    try {
      await _db.from(table).upsert(values);
    } catch (e) {
      throw Exception("Supabase upsert error: $e");
    }
  }

  /// Delete by ID
  static Future<void> delete(String table, String id) async {
    try {
      await _db.from(table).delete().eq("id", id);
    } catch (e) {
      throw Exception("Supabase delete error: $e");
    }
  }
}
