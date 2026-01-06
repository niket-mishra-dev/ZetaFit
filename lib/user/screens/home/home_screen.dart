import 'dart:async';

import 'package:fitmor/services/dashboard_plan_service.dart';
import 'package:fitmor/user/routes/user_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _alpha(double x) => (x * 255).toInt();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String name = "User";
  String gender = "male";
  int workoutsCompleted = 0;
  double caloriesBurned = 0;
  int streakDays = 0;
  List<Map<String, dynamic>> recent = [];
  bool workedOutToday = false;
  final DashboardPlanService _planService = DashboardPlanService();
  Map<String, dynamic>? todayPlan;
  

  // weekly data: map 'YYYY-MM-DD' -> total seconds (or calories)
  final Map<String, double> weeklyTotals = {};

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  final List<String> tips = [
    "Consistency beats intensity — do something today.",
    "Short workouts (10–20 min) are better than none.",
    "Protein after workouts helps recovery — add 20–30g.",
    "Hydrate before and after training.",
    "Sleep >7 hours improves fitness gains.",
  ];

  @override
  void initState() {
    super.initState();

    _init();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadDashboardData();
    _subscribeRealtime();
  }

  Future<void> _loadDashboardData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    try {
      await Future.wait([
        _loadNameGender(user),
        _loadWorkoutsCompleted(user),
        _loadCalories(user),
        _loadStreak(user),
        _loadRecentWorkouts(user),
        _loadWeeklyTotals(user),
        _checkTodayWorkout(user),
        _loadTodayPlan(),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[home] load error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadTodayPlan() async {
    try {
      todayPlan = await _planService.getTodayPlan();
    } catch (e) {
      if (kDebugMode) debugPrint("today plan error: $e");
    }
  }

  Future<void> _loadNameGender(User user) async {
    final metadata = user.userMetadata ?? {};
    name =
        metadata['name'] as String? ?? user.email?.split('@').first ?? "User";
    gender = (metadata['gender'] as String? ?? 'male').toLowerCase();
  }

  Future<void> _loadWorkoutsCompleted(User user) async {
    try {
      final rows = await supabase
          .from('user_workout_history')
          .select('id')
          .eq('user_id', user.id);
      workoutsCompleted = rows.length;
    } catch (e) {
      workoutsCompleted = 0;
      if (kDebugMode) print('[home] loadWorkoutsCompleted error: $e');
    }
  }

  Future<void> _loadCalories(User user) async {
    try {
      final rows = await supabase
          .from('user_workout_history')
          .select('duration_seconds')
          .eq('user_id', user.id);

      double total = 0;
      for (final r in rows) {
        final secs = r['duration_seconds'] ?? 0;
        total += (secs as num) * 0.14;
      }
      caloriesBurned = total;
    } catch (e) {
      caloriesBurned = 0;
      if (kDebugMode) print('[home] loadCalories error: $e');
    }
  }

  Future<void> _loadStreak(User user) async {
    try {
      final rows = await supabase
          .from('user_workout_history')
          .select('completed_at')
          .eq('user_id', user.id);

      final uniqueDays = <String>{};
      for (final r in rows) {
        final raw = r['completed_at'];
        if (raw == null) continue;
        DateTime? ts = raw is DateTime
            ? raw
            : DateTime.tryParse(raw.toString());
        if (ts != null) uniqueDays.add("${ts.year}-${ts.month}-${ts.day}");
      }
      streakDays = uniqueDays.length;
    } catch (e) {
      streakDays = 0;
      if (kDebugMode) print('[home] loadStreak error: $e');
    }
  }

  Future<void> _loadRecentWorkouts(User user) async {
    try {
      final rows = await supabase
          .from('user_workout_history')
          .select('''
          id,
          duration_seconds,
          completed_at,
          workouts (
            id,
            name,
            image_url
          )
        ''')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .limit(5); // ✅ minimum 3–5 items

      recent = rows.map<Map<String, dynamic>>((r) {
        final workout = r['workouts'] ?? {};
        return {
          'id': workout['id'],
          'name': workout['name'],
          'duration_seconds': r['duration_seconds'],
          'completed_at': r['completed_at'],
          'image_path': workout['image_url'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[home] recent workouts error: $e');
      }
    }
  }

  Future<void> _loadWeeklyTotals(User user) async {
    // compute last 7 days keys
    weeklyTotals.clear();
    final now = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );

    for (final d in days) {
      final key = "${d.year}-${d.month}-${d.day}";
      weeklyTotals[key] = 0;
    }

    try {
      // fetch last 14 days (safe) and aggregate
      final rows = await supabase
          .from('user_workout_history')
          .select('duration_seconds, completed_at')
          .eq('user_id', user.id)
          .gte(
            'completed_at',
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 7)).toIso8601String(),
          );

      for (final r in rows) {
        final raw = r['completed_at'];
        DateTime? ts = raw is DateTime
            ? raw
            : DateTime.tryParse(raw.toString());
        if (ts == null) continue;
        final key = "${ts.year}-${ts.month}-${ts.day}";
        final secs = (r['duration_seconds'] ?? 0) as num;
        if (weeklyTotals.containsKey(key)) {
          weeklyTotals[key] = (weeklyTotals[key] ?? 0) + secs.toDouble();
        }
      }
    } catch (e) {
      if (kDebugMode) print('[home] loadWeeklyTotals error: $e');
    }
  }

  Future<void> _checkTodayWorkout(User user) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final rows = await supabase
          .from('user_workout_history')
          .select('id')
          .eq('user_id', user.id)
          .gte('completed_at', startOfDay.toIso8601String())
          .limit(1);

      workedOutToday = rows.isNotEmpty;
    } catch (e) {
      workedOutToday = false;
      if (kDebugMode) debugPrint('[home] checkTodayWorkout error: $e');
    }
  }

  void _subscribeRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Unsubscribe previous channel if exists
    _channel?.unsubscribe();
    _channel = supabase.channel('public:workout_changes_home_${user.id}');

    _channel = supabase
        .channel('workout_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_workout_history',
          callback: (payload) {
            if (kDebugMode) debugPrint("Realtime payload = $payload");
            _loadDashboardData();
          },
        )
        .subscribe();
  }

  Future<void> _onRefresh() async {
    await _loadDashboardData();
  }

  // helper: get tip of the day
  String _tipOfDay() {
    final idx = DateTime.now().day % tips.length;
    return tips[idx];
  }

  // helper: build weekly chart spots from weeklyTotals map (area chart)
  List<FlSpot> _chartSpots() {
    final List<FlSpot> spots = [];
    // ensure sorted by day
    final keys = weeklyTotals.keys.toList()..sort((a, b) => a.compareTo(b));
    for (int i = 0; i < keys.length; i++) {
      // convert seconds -> minutes or calories? Use minutes for curve (secs/60)
      final val = (weeklyTotals[keys[i]] ?? 0) / 60.0; // minutes
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  // For axis labels M T W ...
  List<String> _weekLabels() {
    final now = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    return days
        .map(
          (d) => [
            "Sun",
            "Mon",
            "Tue",
            "Wed",
            "Thu",
            "Fri",
            "Sat",
          ][d.weekday % 7].substring(0, 1),
        )
        .toList();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      // background gradient container
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color(0xFF0D0D0F),
                    Color(0xFF111113),
                    Color(0xFF19191C),
                  ]
                : const [Colors.white, Color(0xFFF6F7FB), Color(0xFFE7EBF1)],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: theme.colorScheme.primary,
                  child: _mainContent(context),
                ),
        ),
      ),

      // Glassy FAB
      floatingActionButton: _buildGlassFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _mainContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 18),
          _buildStatsRow(context),
          const SizedBox(height: 18),

          // Tip of the day
          _buildTipCard(theme),
          const SizedBox(height: 18),

          // Today's plan suggestion
          _buildTodaysPlanCard(theme),
          const SizedBox(height: 18),

          // Weekly progress chart (area)
          _buildWeeklyChartCard(theme),
          const SizedBox(height: 18),

          // Recent workouts list
          _buildRecentWorkouts(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final lottiePath = gender == "female"
        ? "assets/lottie/woman.json"
        : "assets/lottie/man.json";
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(_alpha(0.6)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: GoogleFonts.michroma(
                  color: theme.colorScheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          width: 80,
          child: ClipOval(child: Lottie.asset(lottiePath, fit: BoxFit.cover)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            "Workouts",
            "$workoutsCompleted",
            Icons.fitness_center,
            Colors.cyan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            "Calories",
            caloriesBurned.toStringAsFixed(0),
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _streakCard(context), // Your animated card
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accent,
  ) {
    final theme = Theme.of(context);

    return Container(
      height: 120, // keeps proportions but width is flexible
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withAlpha((0.85 * 255).toInt()),
        border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((0.06 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              theme.brightness == Brightness.dark
                  ? (0.22 * 255).toInt()
                  : (0.08 * 255).toInt(),
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 24),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.55 * 255).toInt(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 110,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withAlpha(_alpha(0.86)),
        border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha(_alpha(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              theme.brightness == Brightness.dark
                  ? (0.22 * 255).toInt()
                  : (0.08 * 255).toInt(),
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt, color: Colors.lightBlueAccent, size: 24),
            const Spacer(),
            // animated number
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: streakDays.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  "${value.toInt()} days",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              "Streak",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(_alpha(0.55)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withAlpha(_alpha(0.12)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.secondary.withAlpha(_alpha(0.25)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, size: 28, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _tipOfDay(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showTipDialog(),
            child: Text(
              "More",
              style: GoogleFonts.montserrat(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlanCard(ThemeData theme) {
    if (todayPlan == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (todayPlan!['type'] == 'workout') {
          Navigator.pushNamed(
            context,
            "/workout-detail",
            arguments: todayPlan!['workout'],
          );
        } else {
          Navigator.pushNamed(context, "/ai-coach");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.today, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayPlan!['message'],
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (todayPlan!['title'] != null)
                    Text(
                      todayPlan!['title'],
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseSupabaseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value.replaceAll(' ', 'T'));
    }
    return null;
  }

  void _showTipDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Daily Tips"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: tips.map((t) => ListTile(title: Text(t))).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyChartCard(ThemeData theme) {
    final spots = _chartSpots();
    final labels = _weekLabels();

    // find max for y-axis
    double maxY = 5; // fallback
    if (spots.isNotEmpty) {
      final localMax = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      maxY = (localMax * 1.3).clamp(5.0, 9999.0);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(_alpha(0.95)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              theme.brightness == Brightness.dark
                  ? (0.12 * 255).toInt()
                  : (0.04 * 255).toInt(),
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Weekly Activity",
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                "${(spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a + b)).toStringAsFixed(0)} min",
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(
                            labels[idx],
                            style: GoogleFonts.montserrat(fontSize: 12),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(enabled: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.24 * 255).toInt()),
                          Theme.of(context).colorScheme.secondary.withAlpha(
                            (0.18 * 255).toInt(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentWorkoutSkeleton(ThemeData theme) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.68,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.08 * 255).toInt(),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withAlpha((0.08 * 255).toInt()),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 80,
            color: theme.colorScheme.onSurface.withAlpha((0.06 * 255).toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkouts(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Recent Workouts",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.of(context).pushNamed(UserRouteNames.recentActivity);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "See all",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 🔹 Skeleton loader
        if (loading)
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) => _recentWorkoutSkeleton(theme),
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemCount: 3,
            ),
          )
        // 🔹 Empty state
        else if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "No recent workouts — start one now!",
              style: GoogleFonts.montserrat(),
            ),
          )
        // 🔹 Actual list
        else
          SizedBox(
            height: 118, // ✅ tight, intentional height
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = recent[index];
                final title = item['name'] ?? 'Workout';
                final secs = (item['duration_seconds'] ?? 0) as num;
                final minutes = (secs / 60).ceil();

                final dt = _parseSupabaseDate(item['completed_at']);
                final dateText = dt != null ? "${dt.day}/${dt.month}" : "";

                return SizedBox(
                  width: 220, // ✅ fixed card width = clean layout
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          UserRouteNames.workoutDetail,
                          arguments: (item['id'] as num).toInt(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TOP ROW: ICON + CHEVRON
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.14),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 22,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // TITLE
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // META
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$minutes min",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  dateText,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Glass-morphic circular FAB
  Widget _buildGlassFab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed("/ai-coach"),
      child: SizedBox(
        width: 78,
        height: 78,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner filled circle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withAlpha((0.9 * 255).toInt()),
                    Colors.lightBlueAccent.withAlpha((0.85 * 255).toInt()),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
