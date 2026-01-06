import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BotAnswerEditorScreen extends StatefulWidget {
  final String questionId;
  final String question;

  const BotAnswerEditorScreen({
    super.key,
    required this.questionId,
    required this.question,
  });

  @override
  State<BotAnswerEditorScreen> createState() =>
      _BotAnswerEditorScreenState();
}

class _BotAnswerEditorScreenState extends State<BotAnswerEditorScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  bool saving = false;

  // --------------------------------------------------
  // SAVE + TRAIN BOT
  // --------------------------------------------------
  Future<void> _save() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;

    setState(() => saving = true);

    try {
      // 1️⃣ Insert into bot_knowledge
      await supabase.from('bot_knowledge').insert({
        'question': widget.question.trim(),
        'answer': answer,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2️⃣ Mark unknown question as trained
      await supabase
          .from('bot_unknown_questions')
          .update({'trained': true})
          .eq('id', widget.questionId);

      if (mounted) {
        Navigator.pop(context, true); // refresh previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
          "Train Bot",
          style: GoogleFonts.michroma(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUESTION
            Text(
              "Question",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Text(
                widget.question,
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // ANSWER
            Text(
              "Bot Answer",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Write the best possible answer for the bot…",
                  filled: true,
                  fillColor:
                      theme.colorScheme.onSurface.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology_rounded),
                label: Text(
                  saving ? "Training…" : "Save & Train Bot",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
