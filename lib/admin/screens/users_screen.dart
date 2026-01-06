import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> users = [];
  String query = '';
  bool loading = true;

  // ===========================================================
  // ZETAFIT COLORS
  // ===========================================================
  static const Color primaryNeon = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF2ED1);
  static const Color accentPurple = Color(0xFFB388FF);

  static const Color darkBg = Color(0xFF0D0D0F);
  static const Color darkCard = Color(0xFF1A1A1E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await supabase
        .from('profiles')
        .select('id, name, email, gender, height, weight, created_at')
        .order('created_at', ascending: false);

    setState(() {
      users = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final email = (u['email'] ?? '').toString().toLowerCase();
      final name = (u['name'] ?? '').toString().toLowerCase();
      return email.contains(query.toLowerCase()) ||
          name.contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // SEARCH
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon:
                      Icon(Icons.search, color: primaryNeon),
                  filled: true,
                  fillColor: darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // LIST
            // =========================
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryNeon,
                      ),
                    )
                  : filtered.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 20),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) =>
                              _userCard(filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // USER CARD
  // =========================
  Widget _userCard(Map<String, dynamic> u) {
    final String name =
        u['name'] ?? u['email']?.split('@').first ?? 'User';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          // AVATAR
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryNeon, width: 1.5),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: primaryNeon,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  u['email'] ?? '',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // STATS
                Wrap(
                  spacing: 10,
                  children: [
                    _chip(u['gender'], accentPurple),
                    _chip(
                        u['height'] != null
                            ? '${u['height']} cm'
                            : null,
                        primaryNeon),
                    _chip(
                        u['weight'] != null
                            ? '${u['weight']} kg'
                            : null,
                        neonPink),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // CHIP
  // =========================
  Widget _chip(String? text, Color color) {
    if (text == null || text.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // =========================
  // EMPTY
  // =========================
  Widget _emptyState() {
    return Center(
      child: Text(
        'No users found',
        style: GoogleFonts.montserrat(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }
}
