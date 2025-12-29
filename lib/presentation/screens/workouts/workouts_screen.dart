import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'workout_list_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String search = "";

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // --------------------------------------------------
  // LOAD DATA
  // --------------------------------------------------
  Future<void> _loadCategories() async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('workout_categories')
          .select('id, name, image_url')
          .order('id');

      categories = data.map<Map<String, dynamic>>((e) => e).toList();
      filtered = categories;
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      categories = [];
      filtered = [];
    }

    if (mounted) setState(() => loading = false);
  }

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------
  void _onSearch(String value) {
    setState(() {
      search = value.toLowerCase();
      filtered = categories
          .where(
            (c) =>
                c['name']
                    .toString()
                    .toLowerCase()
                    .contains(search),
          )
          .toList();
    });
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadCategories,
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Text(
                "Workout Categories",
                style: GoogleFonts.michroma(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 14),

              // SEARCH
              TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: "Search workouts...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // CONTENT
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? _emptyState()
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (context, index) {
                              return _categoryCard(
                                context,
                                filtered[index],
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY CARD
  // --------------------------------------------------
  Widget _categoryCard(BuildContext context, Map item) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutListScreen(
              title: item["name"],
              categoryId: item["id"],
            ),
          ),
        );
      },
      child: Hero(
        tag: "category_${item["id"]}",
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(item["image_url"]),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(190, 0, 0, 0),
                  Color.fromARGB(40, 0, 0, 0),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            padding: const EdgeInsets.all(14),
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item["name"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            "No categories found",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
