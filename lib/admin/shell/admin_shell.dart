import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/bot_answer_list_screen.dart';
import '../screens/broadcast_notification_screen.dart';
import '../screens/users_screen.dart';
import '../screens/workout_analytics_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  final List<_AdminNavItem> items = const [
    _AdminNavItem(
      label: "Bot Training",
      icon: Icons.psychology_rounded,
      screen: BotAnswerListScreen(),
    ),
    _AdminNavItem(
      label: "Motivate Users",
      icon: Icons.campaign_rounded,
      screen: BroadcastNotificationScreen(),
    ),
    _AdminNavItem(
      label: "Community",
      icon: Icons.people_rounded,
      screen: UserListScreen(),
    ),
    _AdminNavItem(
      label: "Analytics",
      icon: Icons.bar_chart_rounded,
      screen: WorkoutAnalyticsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          items[index].label,
          style: GoogleFonts.michroma(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              
              await Supabase.instance.client.auth.signOut();

            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _sideNav(theme),
          Expanded(child: items[index].screen),
        ],
      ),
      bottomNavigationBar: isWide ? null : _bottomNav(theme),
    );
  }

  // --------------------------------------------------
  // 🌑 SIDE NAV (DESKTOP / TABLET)
  // --------------------------------------------------

  Widget _sideNav(ThemeData theme) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              "NAVIGATION",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),

          ...List.generate(items.length, (i) {
            final selected = i == index;
            final item = items[i];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    item.icon,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  title: Text(
                    item.label,
                    style: GoogleFonts.montserrat(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  onTap: () => setState(() => index = i),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // 🌑 BOTTOM NAV (MOBILE)
  // --------------------------------------------------

  Widget _bottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor:
            theme.colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(),
        items: items
            .map(
              (e) => BottomNavigationBarItem(
                icon: Icon(e.icon),
                label: e.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}
