import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bot_answer_editor_screen.dart';

class BotInboxScreen extends StatefulWidget {
  const BotInboxScreen({super.key});

  @override
  State<BotInboxScreen> createState() => _BotInboxScreenState();
}

class _BotInboxScreenState extends State<BotInboxScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> questions = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD UNTRAINED QUESTIONS
  // --------------------------------------------------
  Future<void> _load() async {
    setState(() => loading = true);

    final res = await supabase
        .from('bot_unknown_questions')
        .select('id, question, created_at')
        .eq('trained', false)
        .order('created_at', ascending: false);

    setState(() {
      questions = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  // --------------------------------------------------
  // REALTIME SUBSCRIPTION
  // --------------------------------------------------
  void _subscribeRealtime() {
    _channel?.unsubscribe();

    _channel = supabase
        .channel('bot_inbox_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bot_unknown_questions',
          callback: (_) => _load(),
        )
        .subscribe();
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
          "Bot Inbox",
          style: GoogleFonts.michroma(fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? _emptyState(theme)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _questionTile(theme, questions[i]),
                ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------
  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
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

  // --------------------------------------------------
  // QUESTION TILE
  // --------------------------------------------------
  Widget _questionTile(
    ThemeData theme,
    Map<String, dynamic> q,
  ) {
    final String question = (q['question'] ?? '').toString();
    final String id = q['id'].toString();
    final String createdAt = q['created_at']?.toString() ?? '';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final trained = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BotAnswerEditorScreen(
                questionId: id,
                question: question,
              ),
            ),
          );

          if (trained == true) {
            _load();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.isEmpty ? "Unknown question" : question,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _time(createdAt),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TIME FORMAT
  // --------------------------------------------------
  String _time(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return "just now";

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
