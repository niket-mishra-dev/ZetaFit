import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  String name = "User";
  String email = "";
  String uid = "";
  String gender = "male";

  int workoutsCompleted = 0;
  double caloriesBurned = 0;
  int streakDays = 0;
  String? avatarUrl;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    _loadProfileData();

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated) {
        final user = data.session?.user;

        if (user != null) {
          setState(() {
            avatarUrl = user.userMetadata?["avatar_url"];
            name = user.userMetadata?["full_name"];
            gender = user.userMetadata?["gender"];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    email = user.email ?? "No Email";
    uid = user.id;
    name = user.userMetadata?["full_name"] ?? email.split('@').first;
    gender = (user.userMetadata?["gender"] ?? "male").toLowerCase();
    avatarUrl = user.userMetadata?["avatar_url"];

    await Future.wait([
      _loadWorkoutsCompleted(user),
      _loadCalories(user),
      _loadStreak(user),
    ]);

    if (mounted) setState(() => loading = false);
  }

  // --------------------------------------------------------
  // WORKOUTS COMPLETED COUNT
  // --------------------------------------------------------
  Future<void> _loadWorkoutsCompleted(User user) async {
    try {
      final rows = await supabase
          .from("user_workout_history")
          .select("id")
          .eq("user_id", user.id);

      workoutsCompleted = rows.length;
    } catch (_) {
      workoutsCompleted = 0;
    }
  }

  // --------------------------------------------------------
  // CALORIES BURNED (sum(duration_seconds * factor))
  // --------------------------------------------------------
  Future<void> _loadCalories(User user) async {
    try {
      final rows = await supabase
          .from("user_workout_history")
          .select("duration_seconds")
          .eq("user_id", user.id);

      double total = 0;

      for (final r in rows) {
        final secs = r["duration_seconds"] ?? 0;
        total += secs * 0.14;
      }

      caloriesBurned = total;
    } catch (_) {
      caloriesBurned = 0;
    }
  }

  // --------------------------------------------------------
  // STREAK DAYS (count distinct completed_at dates)
  // --------------------------------------------------------
  Future<void> _loadStreak(User user) async {
    try {
      final rows = await supabase
          .from("user_workout_history")
          .select("completed_at")
          .eq("user_id", user.id);

      final Set<String> days = {};

      for (final r in rows) {
        final raw = r["completed_at"];
        if (raw == null) continue;

        final dt = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
        if (dt != null) {
          days.add("${dt.year}-${dt.month}-${dt.day}");
        }
      }

      streakDays = days.length;
    } catch (_) {
      streakDays = 0;
    }
  }

  // --------------------------------------------------------
  // UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(0), // or some radius
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color(0xFF0D0D0F),
                    Color(0xFF17171A),
                    Color(0xFF1C1C22),
                  ]
                : const [Colors.white, Color(0xFFF3F4F7), Color(0xFFE4E6EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(theme),
                      const SizedBox(height: 16),
                      _buildUserInfo(theme),
                      const SizedBox(height: 20),
                      _buildStatsRow(theme),
                      const SizedBox(height: 20),
                      _buildSettingsSection(theme, context),
                      const SizedBox(height: 30),
                      _logoutButton(theme),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Avatar
  // --------------------------------------------------------
  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipOval(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.7),
                  theme.colorScheme.secondary.withOpacity(0.6),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 55,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    )
                  : null,
            ),
          ),
        ),

        // Pencil Icon
        GestureDetector(
          onTap: _openAvatarOptions,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // User Info
  // --------------------------------------------------------
  Widget _buildUserInfo(ThemeData theme) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.michroma(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
          ),
        ),
        Text(
          email,
          style: GoogleFonts.michroma(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          uid,
          style: GoogleFonts.montserrat(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // Stats Row
  // --------------------------------------------------------
  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statCard(
          theme,
          "Workouts",
          "$workoutsCompleted",
          Icons.fitness_center,
        ),
        _statCard(
          theme,
          "Calories",
          caloriesBurned.toStringAsFixed(0),
          Icons.local_fire_department,
        ),
        _statCard(theme, "Streak", "$streakDays Days", Icons.bolt),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String title, String value, IconData icon) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.10,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2), // FIXED
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Settings
  // --------------------------------------------------------
  Widget _buildSettingsSection(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _settingsTile(theme, Icons.person_outline, "Edit Profile", () => Navigator.pushNamed(context, "/edit-profile")),
        _settingsTile(theme, Icons.support_agent, "Contact Us", () => Navigator.pushNamed(context, "/contact")),
        _settingsTile(theme, Icons.notifications_none, "Notifications", () => Navigator.pushNamed(context, "/notifications")),
        _settingsTile(
          theme,
          Icons.privacy_tip_outlined,
          "Privacy Policy",
          () => Navigator.pushNamed(context, "/privacy"),
        ),
        _settingsTile(theme, Icons.feedback_outlined, "Feedback", () => Navigator.pushNamed(context, "/feedback")),
        _settingsTile(theme, Icons.question_answer_outlined, "FAQs", () => Navigator.pushNamed(context, "/faqs")),
        _settingsTile(theme, Icons.info_outline, "About", () => Navigator.pushNamed(context, "/about")),
      ],
    );
  }

  Widget _settingsTile(
    ThemeData theme,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }

  // --------------------------------------------------------
  // Logout Button
  // --------------------------------------------------------
  Widget _logoutButton(ThemeData theme) {
    return TextButton(
      onPressed: () async {
        await supabase.auth.signOut();
      },
      child: Text(
        "Logout",
        style: GoogleFonts.montserrat(
          color: theme.colorScheme.error,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openAvatarOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset + 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Edit Avatar"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/edit-profile");
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Remove Avatar"),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeAvatar() async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            "avatar_url": null, // Remove metadata entry
          },
        ),
      );

      setState(() {
        avatarUrl = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Avatar removed")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
