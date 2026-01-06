import 'package:fitmor/shared/models/activity_model.dart';
import 'package:fitmor/user/routes/user_routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  final supabase = Supabase.instance.client;
  final ScrollController _scroll = ScrollController();

  final List<Activity> _activities = [];
  bool _loading = true;
  bool _fetchingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 20;
  int _page = 0;

  @override
  void initState() {
    super.initState();

    // Load cache first (offline)
    final cached = ActivityCache.getAll();
    if (cached.isNotEmpty) {
      _activities.addAll(cached);
      _loading = false;
    }

    _loadPage();

    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 &&
          !_fetchingMore &&
          _hasMore) {
        _loadPage();
      }
    });
  }

  Map<DateTime, int> buildDailyTotals(List<Activity> activities) {
    final map = <DateTime, int>{};

    for (final a in activities) {
      final date = DateUtils.dateOnly(a.completedAt);
      map[date] = (map[date] ?? 0) + a.durationMinutes;
    }

    return map;
  }

  Color heatColor(BuildContext context, int minutes) {
    final scheme = Theme.of(context).colorScheme;

    if (minutes == 0) {
      return scheme.onSurface.withValues(alpha: 0.08);
    }

    if (minutes < 10) {
      return scheme.primary.withValues(alpha: 0.55);
    }

    if (minutes < 20) {
      return scheme.primary.withValues(alpha: 0.65);
    }

    if (minutes < 30) {
      return scheme.primary.withValues(alpha: 0.75);
    }

    if (minutes < 40) {
      return scheme.primary.withValues(alpha: 0.85);
    }

    if (minutes < 50) {
      return scheme.primary.withValues(alpha: 0.95);
    }

    return scheme.primary;
  }

  Future<void> _loadPage() async {
    if (_fetchingMore) return;

    setState(() => _fetchingMore = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final from = _page * _pageSize;
      final to = from + _pageSize - 1;

      final rows = await supabase
          .from('user_workout_history')
          .select('''
            id,
            completed_at,
            duration_seconds,
            workouts (
              id,
              name,
              image_url
            )
          ''')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .range(from, to);

      final newItems = rows.map<Activity>((e) => Activity.fromMap(e)).toList();

      if (newItems.length < _pageSize) _hasMore = false;

      _activities.addAll(newItems);
      ActivityCache.save(_activities);

      _page++;
    } catch (e) {
      debugPrint('RecentActivity error: $e');
    } finally {
      setState(() {
        _loading = false;
        _fetchingMore = false;
      });
    }
  }

  Map<String, List<Activity>> _grouped() {
    final map = <String, List<Activity>>{};
    for (final a in _activities) {
      final key = DateFormat(
        'EEE, dd MMM',
      ).format(DateUtils.dateOnly(a.completedAt));
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _grouped();
    final dailyTotals = buildDailyTotals(_activities);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Activity', style: GoogleFonts.michroma()),
      ),
      body: _loading && _activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                _heatmap(theme, dailyTotals),
                const SizedBox(height: 20),
                ...grouped.entries.map((e) => _section(theme, e.key, e.value)),
                if (_fetchingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // HEATMAP (Weekly / Monthly)
  // ------------------------------------------------------------
  Widget _heatmap(ThemeData theme, Map<DateTime, int> totals) {
    final now = DateTime.now();
    final days = List.generate(
      28,
      (i) => DateUtils.dateOnly(now.subtract(Duration(days: i))),
    ).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Heatmap',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: days.map((d) {
            final minutes = totals[d] ?? 0;
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: heatColor(context, minutes),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DATE SECTION
  // ------------------------------------------------------------
  Widget _section(ThemeData theme, String header, List<Activity> items) {
    final total = items.fold<int>(0, (sum, a) => sum + a.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            children: [
              Text(
                header,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$total min',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...items.map((a) => _tile(theme, a)),
      ],
    );
  }

  // ------------------------------------------------------------
  // ACTIVITY TILE + HERO
  // ------------------------------------------------------------
  Widget _tile(ThemeData theme, Activity a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias, // 🔑 THIS FIXES THE BORDER ISSUE
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed(UserRouteNames.workoutDetail, arguments: a.workoutId);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Hero(
                  tag: 'workout_${a.workoutId}',
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.12,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.workoutName,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${a.durationMinutes} min',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
