import 'dart:async';

import 'package:fitmor/presentation/screens/progress/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/workouts/workouts_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final supabase = Supabase.instance.client;

  late final StreamSubscription<AuthState> _authSub;
  RealtimeChannel? _notificationChannel;

  bool isSignedIn = false;
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

    isSignedIn = supabase.auth.currentUser != null;

    if (isSignedIn) {
      _loadUnreadNotifications();
      _subscribeNotificationRealtime();
    }

    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        setState(() => isSignedIn = true);
        _loadUnreadNotifications();
        _subscribeNotificationRealtime();
      } else if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          isSignedIn = false;
          hasUnreadNotifications = false;
        });
        _notificationChannel?.unsubscribe();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  // --------------------------------------------------
  // 🔔 NOTIFICATION BADGE LOGIC
  // --------------------------------------------------

  Future<void> _loadUnreadNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .limit(1);

      if (mounted) {
        setState(() => hasUnreadNotifications = res.isNotEmpty);
      }
    } catch (_) {
      // silent fail (badge is non-critical)
    }
  }

  void _subscribeNotificationRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _notificationChannel?.unsubscribe();

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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isSignedIn
          ? _SignedInScaffold(
              key: const ValueKey("signed-in"),
              tabIndex: tabIndex,
              onTabChange: (i) => setState(() => tabIndex = i),
              children: tabs,
              hasUnreadNotifications: hasUnreadNotifications,
            )
          : LoginScreen(key: ValueKey("login")),
    );
  }
}

// ----------------------------------------------------------------
// SIGNED-IN SCAFFOLD
// ----------------------------------------------------------------

class _SignedInScaffold extends StatelessWidget {
  final int tabIndex;
  final List<Widget> children;
  final ValueChanged<int> onTabChange;
  final bool hasUnreadNotifications;

  const _SignedInScaffold({
    super.key,
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/notifications');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 26),

                  // 🔴 UNREAD DOT
                  if (hasUnreadNotifications)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
// 💎 PREMIUM NAV BAR
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
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? theme.colorScheme.surface.withOpacity(0.92)
        : Colors.white.withOpacity(0.96);

    final highlightColor = isDark
        ? theme.colorScheme.primaryContainer.withOpacity(0.35)
        : theme.colorScheme.primary.withOpacity(0.18);

    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(
              isDark ? 0.10 : 0.06,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: onTabChange,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor:
            theme.colorScheme.onSurface.withOpacity(0.55),
        selectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
        items: [
          _item(Icons.home_rounded, "Home", 0, highlightColor),
          _item(Icons.fitness_center_rounded, "Workouts", 1, highlightColor),
          _item(Icons.trending_up_rounded, "Progress", 2, highlightColor),
          _item(Icons.person_rounded, "Profile", 3, highlightColor),
        ],
      ),
    );
  }

  BottomNavigationBarItem _item(
    IconData icon,
    String label,
    int index,
    Color highlight,
  ) {
    final selected = tabIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? highlight : Colors.transparent,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 240),
          scale: selected ? 1.18 : 1.0,
          child: Icon(icon),
        ),
      ),
    );
  }
}
