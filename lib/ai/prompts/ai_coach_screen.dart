import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../repository/ai_repository.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final AIRepository _repo = AIRepository();
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String? _response;

  final List<String> _suggestions = const [
    "Create a 20-minute upper-body workout I can do at home",
    "Recommend a post-workout meal (400-500 kcal)",
    "I only have resistance bands — suggest a full-body routine",
    "How should I adjust workouts for knee pain?",
    "Give me a quick morning stretching routine",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -----------------------
  // SEND PROMPT
  // -----------------------
  Future<void> _sendPrompt(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a prompt")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _response = null;
    });

    try {
      final reply = await _repo.generateAICoaching(userPrompt: text);
      if (!mounted) return;
      setState(() => _response = reply);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint("LocalBot error: $e\n$st");
      }
      if (!mounted) return;
      setState(() {
        _response = "⚠️ Something went wrong. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applySuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
  }

  // -----------------------
  // HEADER
  // -----------------------
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Zeta AI",
                      style: GoogleFonts.michroma(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Ask about workouts, diet, stretching & recovery",
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------
  // PROMPT BOX
  // -----------------------
  Widget _buildPromptBox(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Ask e.g. 'Build a 4-week fat loss plan'",
              hintStyle: GoogleFonts.montserrat(fontSize: 13),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),

          // Suggestions
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return GestureDetector(
                  onTap: () => _applySuggestion(s),
                  child: Chip(
                    avatar: const Icon(Icons.flash_on, size: 16),
                    label: Text(
                      s.length > 30 ? "${s.substring(0, 30)}…" : s,
                      style: GoogleFonts.montserrat(fontSize: 13),
                    ),
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _sendPrompt(_controller.text),
                  icon: const Icon(Icons.send),
                  label: Text(
                    "Generate",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  setState(() => _response = null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------
  // RESPONSE CARD
  // -----------------------
  Widget _buildResponse(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Generating advice…"),
          ],
        ),
      );
    }

    if (_response == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text("No response yet — ask something to begin."),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Your AI Advice",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _response!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to clipboard")),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _response!,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------
  // BUILD
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context),
            _buildPromptBox(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildResponse(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
