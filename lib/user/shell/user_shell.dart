import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/progress/progress_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _notificationChannel;

  bool hasUnreadNotifications = false;
  int tabIndex = 0;

  final tabs = const [
    HomeScreen(),
    WorkoutsScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
    _subscribeNotificationRealtime();
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  // --------------------------------------------------
  // 🔔 NOTIFICATION BADGE
  // --------------------------------------------------

  Future<void> _loadUnreadNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false)
        .limit(1);

    if (mounted) {
      setState(() => hasUnreadNotifications = res.isNotEmpty);
    }
  }

  void _subscribeNotificationRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _notificationChannel = supabase
        .channel('notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _loadUnreadNotifications(),
        )
        .subscribe();
  }

  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return _SignedInScaffold(
      tabIndex: tabIndex,
      onTabChange: (i) => setState(() => tabIndex = i),
      children: tabs,
      hasUnreadNotifications: hasUnreadNotifications,
    );
  }
}

// ----------------------------------------------------------------
// SIGNED-IN UI
// ----------------------------------------------------------------

class _SignedInScaffold extends StatelessWidget {
  final int tabIndex;
  final List<Widget> children;
  final ValueChanged<int> onTabChange;
  final bool hasUnreadNotifications;

  const _SignedInScaffold({
    required this.tabIndex,
    required this.children,
    required this.onTabChange,
    required this.hasUnreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ZetaFit",
          style: GoogleFonts.michroma(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: IndexedStack(index: tabIndex, children: children),
      bottomNavigationBar: _PremiumNavBar(
        tabIndex: tabIndex,
        onTabChange: onTabChange,
      ),
    );
  }
}

// ----------------------------------------------------------------
// 💎 NAV BAR
// ----------------------------------------------------------------

class _PremiumNavBar extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChange;

  const _PremiumNavBar({
    required this.tabIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: tabIndex,
      onTap: onTabChange,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_rounded),
          label: 'Workouts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_rounded),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
