import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayPlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onStart;

  const TodayPlanCard({
    super.key,
    required this.data,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = data['state'];

    Color accent;
    String title;
    String subtitle;

    switch (state) {
      case 'workout':
        accent = Colors.green;
        title = "Today • Day ${data['day']}";
        subtitle = data['plan']['name'];
        break;
      case 'rest':
        accent = Colors.blue;
        title = "Rest Day";
        subtitle = data['message'];
        break;
      case 'missed':
        accent = Colors.orange;
        title = "Missed Day";
        subtitle = data['message'];
        break;
      default:
        accent = Colors.grey;
        title = "Your Plan";
        subtitle = data['message'] ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              )),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              state == "rest" ? "Take it easy" : "Start",
            ),
          ),
        ],
      ),
    );
  }
}
