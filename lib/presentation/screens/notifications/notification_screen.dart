import 'dart:async';

import 'package:fitmor/presentation/screens/notifications/notification_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<AppNotification> notifications = [];

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // --------------------------------------------------
  // FETCH
  // --------------------------------------------------
  Future<void> _loadNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final rows = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      notifications =
          rows.map<AppNotification>((e) => AppNotification.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Notification fetch error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // REALTIME SUBSCRIPTION
  // --------------------------------------------------
  void _subscribeRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _channel = supabase
        .channel('user_notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _loadNotifications(),
        )
        .subscribe();
  }

  // --------------------------------------------------
  // MARK READ
  // --------------------------------------------------
  Future<void> _markAsRead(String id) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', id);
  }

  // --------------------------------------------------
  // DELETE
  // --------------------------------------------------
  Future<void> _delete(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.michroma(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _empty(theme)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = notifications[index];

                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(n.id),
                      child: _tile(context, theme, n),
                    );
                  },
                ),
    );
  }

  // --------------------------------------------------
  // TILE
  // --------------------------------------------------
  Widget _tile(
    BuildContext context,
    ThemeData theme,
    AppNotification n,
  ) {
    return Material(
      color: n.isRead
          ? theme.colorScheme.surface
          : theme.colorScheme.primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await _markAsRead(n.id);

          if (n.deepLink != null) {
            Navigator.of(context).pushNamed(n.deepLink!);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationDetailScreen(
                  title: n.title,
                  message: n.message,
                  icon: Icons.notifications,
                  time: _timeAgo(n.createdAt),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _icon(theme, n),
              const SizedBox(width: 14),
              Expanded(child: _text(theme, n)),
              if (!n.isRead) _dot(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(ThemeData theme, AppNotification n) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.14),
      ),
      child: Icon(
        Icons.notifications,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _text(ThemeData theme, AppNotification n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n.title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          n.message,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _timeAgo(n.createdAt),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  Widget _dot(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // TIME FORMAT
  // --------------------------------------------------
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

// --------------------------------------------------
// MODEL
// --------------------------------------------------
class AppNotification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String? deepLink;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.deepLink,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    return AppNotification(
      id: m['id'],
      title: m['title'],
      message: m['message'],
      isRead: m['is_read'] ?? false,
      deepLink: m['deep_link'],
      createdAt: DateTime.parse(m['created_at']),
    );
  }
}
