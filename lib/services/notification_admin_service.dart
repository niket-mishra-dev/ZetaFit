import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // -----------------------------------------------------------
  // SINGLE USER
  // -----------------------------------------------------------
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title.trim(),
      'message': message.trim(),
      'type': type, // ✅ REQUIRED
    });
  }

  // -----------------------------------------------------------
  // BROADCAST
  // -----------------------------------------------------------
  static Future<int> broadcast({
    required String title,
    required String message,
    String type = 'broadcast',
  }) async {
    final users =
        await _supabase.from('profiles').select('id');

    if (users.isEmpty) return 0;

    final payload = users.map((u) {
      return {
        'user_id': u['id'],
        'title': title.trim(),
        'message': message.trim(),
        'type': type, // ✅ REQUIRED
      };
    }).toList();

    await _supabase.from('notifications').insert(payload);
    return payload.length;
  }

  // -----------------------------------------------------------
  // MULTI USER
  // -----------------------------------------------------------
  static Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'system',
  }) async {
    final payload = userIds.map((id) {
      return {
        'user_id': id,
        'title': title.trim(),
        'message': message.trim(),
        'type': type, // ✅ REQUIRED
      };
    }).toList();

    await _supabase.from('notifications').insert(payload);
  }
}
