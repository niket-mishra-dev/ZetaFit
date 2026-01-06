import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BotAnswerListScreen extends StatefulWidget {
  const BotAnswerListScreen({super.key});

  @override
  State<BotAnswerListScreen> createState() => _BotAnswerListScreenState();
}

class _BotAnswerListScreenState extends State<BotAnswerListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // pagination
  static const int pageSize = 10;
  int page = 0;
  bool loading = false;
  bool hasMore = true;

  // data
  final List<Map<String, dynamic>> questions = [];
  final Map<String, TextEditingController> controllers = {};
  final Set<String> trainingIds = {};

  final ScrollController scrollController = ScrollController();
  String? errorMessage;

  // --------------------------------------------------
  // SAFE SETSTATE
  // --------------------------------------------------
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // --------------------------------------------------
  // INIT / DISPOSE
  // --------------------------------------------------
  @override
  void initState() {
    super.initState();
    _reloadAll();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();

    for (final c in controllers.values) {
      c.dispose();
    }
    controllers.clear();

    super.dispose();
  }

  // --------------------------------------------------
  // RESET + LOAD
  // --------------------------------------------------
  Future<void> _reloadAll() async {
    safeSetState(() {
      page = 0;
      hasMore = true;
      loading = false;
      questions.clear();
      errorMessage = null;
    });

    await _loadPage();
  }

  // --------------------------------------------------
  // INFINITE SCROLL
  // --------------------------------------------------
  void _onScroll() {
    if (!mounted) return;

    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300 &&
        !loading &&
        hasMore) {
      _loadPage();
    }
  }

  // --------------------------------------------------
  // LOAD PAGE
  // --------------------------------------------------
  Future<void> _loadPage() async {
    if (loading || !mounted) return;

    safeSetState(() => loading = true);

    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final res = await supabase
          .from('bot_unknown_questions')
          .select()
          .eq('training_status', 'pending')
          .order('created_at', ascending: false)
          .range(from, to);

      if (!mounted) return;

      final data = List<Map<String, dynamic>>.from(res);

      safeSetState(() {
        questions.addAll(data);
        page++;
        hasMore = data.length == pageSize;
      });
    } catch (_) {
      safeSetState(() {
        errorMessage = 'Failed to load questions';
      });
    } finally {
      safeSetState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // TRAIN BOT (OPTIMISTIC)
  // --------------------------------------------------
  Future<void> _trainQuestion({required Map<String, dynamic> q}) async {
    final String id = q['id'];
    final String question = q['question'];
    final controller = controllers[id];

    if (controller == null) return;

    final answer = controller.text.trim();
    if (answer.isEmpty || trainingIds.contains(id)) return;

    safeSetState(() {
      trainingIds.add(id);
      questions.remove(q);
    });

    try {
      await supabase.from('bot_knowledge').insert({
        'question': question,
        'answer': answer,
      });

      await supabase.from('bot_training_logs').insert({
        'admin_id': supabase.auth.currentUser!.id,
        'unknown_question_id': id,
        'question': question,
        'answer': answer,
      });

      await supabase
          .from('bot_unknown_questions')
          .update({'training_status': 'trained'})
          .eq('id', id);

      controllers.remove(id)?.dispose();
    } catch (_) {
      if (!mounted) return;

      safeSetState(() {
        questions.insert(0, q);
        errorMessage = 'Training failed. Try again.';
      });
    } finally {
      safeSetState(() => trainingIds.remove(id));
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          if (errorMessage != null) _errorBanner(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadAll,
              child: questions.isEmpty && !loading
                  ? _emptyState(theme)
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, index) {
                        if (index >= questions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _questionCard(theme, questions[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // ERROR BANNER
  // --------------------------------------------------
  Widget _errorBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.error.withOpacity(0.15),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: GoogleFonts.montserrat(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => safeSetState(() => errorMessage = null),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CARD
  // --------------------------------------------------
  Widget _questionCard(ThemeData theme, Map<String, dynamic> q) {
    final String id = q['id'];
    final String question = q['question'];

    final controller =
        controllers.putIfAbsent(id, () => TextEditingController());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Write the correct bot answer…',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed:
                  trainingIds.contains(id) ? null : () => _trainQuestion(q: q),
              child: trainingIds.contains(id)
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Train Bot'),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY
  // --------------------------------------------------
  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Colors.green.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            "All questions are trained 🎉",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
