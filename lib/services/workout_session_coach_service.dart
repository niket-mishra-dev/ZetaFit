class WorkoutSessionCoachService {
  static String cueForSet(int set, int totalSets) {
    if (set == 1) {
      return "Focus on form. Start slow and controlled 💪";
    }
    if (set == totalSets) {
      return "Final set! Push with good form 🔥";
    }
    return "Great job. Control your breathing.";
  }

  static String restCue(int seconds) {
    if (seconds > 20) {
      return "Breathe deeply through your nose.";
    }
    return "Get ready — next set coming!";
  }

  static String finishMessage() {
    return "Amazing work 🎉 You’re building consistency!";
  }

  static String missedDayRecovery(int missedDays) {
    if (missedDays <= 1) {
      return "Welcome back! Let’s ease in today.";
    }
    return "You took a break — that’s okay. Restart strong 💪";
  }
}
